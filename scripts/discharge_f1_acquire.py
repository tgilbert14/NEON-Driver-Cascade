#!/usr/bin/env python3
"""Authenticated, fail-closed acquisition process for Discharge Gate F1.

The process performs one token-bearing POST to the official NEON data-query
endpoint.  It follows download routes only for preregistered metadata after the
pure contract has classified each filename; observation routes are never read
from the manifest object.  Raw responses and signed capabilities remain in
memory, and only four canonical values-free receipt files are written.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, replace
import gc
import json
import os
from pathlib import Path
import signal
import stat
import sys
import time
from typing import Callable, NoReturn
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import (
    HTTPRedirectHandler,
    Request,
    build_opener,
)

import discharge_f1_contract as contract


API_ORIGIN = "https://data.neonscience.org"
RELEASE_PATH = "/api/v0/releases/RELEASE-2026"
QUERY_PATH = "/api/v0/data/query"
USER_AGENT = "NEON-Driver-Cascade/discharge-feasibility-f1-v1"
JSON_LIMIT = 64 * 1024 * 1024
METADATA_LIMIT = 32 * 1024 * 1024
ATTEMPTS = 4
BACKOFF_SECONDS = (2, 4, 8)
TIMEOUT_SECONDS = 45
OUTPUT_NAMES = (
    "discharge-f1-release-receipt.json",
    "discharge-f1-file-inventory.tsv",
    "discharge-f1-schema-inventory.tsv",
    "discharge-f2-file-allowlist.tsv",
)


@dataclass(frozen=True)
class SanitizedAcquisition:
    availability_sha256: str
    records: tuple[contract.FileRecord, ...]
    schema_rows: tuple[dict[str, object], ...]


def fail(code: str) -> NoReturn:
    raise contract.F1Error(code)


def _bounded_read(response, limit: int, expected_size: int | None = None) -> bytes:
    length = response.headers.get("Content-Length")
    if length is not None:
        try:
            declared = int(length)
        except ValueError:
            fail("metadata_download_failed")
        if declared < 0 or declared > limit or (expected_size is not None and declared != expected_size):
            fail("metadata_download_failed")
    encoding = response.headers.get("Content-Encoding")
    if encoding not in (None, "", "identity"):
        fail("metadata_download_failed")
    raw = response.read(limit + 1)
    if len(raw) > limit or (expected_size is not None and len(raw) != expected_size):
        fail("metadata_download_failed")
    return raw


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: D401
        return None


class MetadataRedirect(HTTPRedirectHandler):
    """Allow one HTTPS redirect that preserves the exact classified basename."""

    def __init__(self, expected_name: str):
        super().__init__()
        self.expected_name = expected_name
        self.hops = 0

    def _checked(self, route: str) -> str:
        route = contract.validated_route(route)
        parsed = urlsplit(route)
        if parsed.path.rsplit("/", 1)[-1] != self.expected_name:
            fail("manifest_allowlist_mismatch")
        return route

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        self.hops += 1
        if self.hops > 1 or code not in {301, 302, 303, 307, 308}:
            fail("manifest_allowlist_mismatch")
        checked = self._checked(newurl)
        return Request(
            checked,
            headers={"Accept": "application/octet-stream", "User-Agent": USER_AGENT},
            method="GET",
        )


class HTTPTransport:
    def __init__(self, sleep: Callable[[float], None] = time.sleep):
        self.sleep = sleep

    def _retry_delay(self, attempt: int) -> None:
        if attempt < ATTEMPTS - 1:
            self.sleep(BACKOFF_SECONDS[attempt])

    def api_request(
        self,
        *,
        method: str,
        path: str,
        body: bytes | None,
        token: str | None,
    ) -> bytes:
        if method not in {"GET", "POST"} or path not in {RELEASE_PATH, QUERY_PATH}:
            fail("manifest_allowlist_mismatch")
        if (path == QUERY_PATH) != bool(token):
            fail("credential_or_capability_exposed")
        url = API_ORIGIN + path
        headers = {
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        }
        if method == "POST":
            headers["Content-Type"] = "application/json"
            headers["X-API-Token"] = token or ""
        opener = build_opener(NoRedirect())
        for attempt in range(ATTEMPTS):
            request = Request(url, data=body, headers=headers, method=method)
            try:
                with opener.open(request, timeout=TIMEOUT_SECONDS) as response:
                    if response.status != 200 or response.geturl() != url:
                        fail("api_request_failed")
                    content_type = response.headers.get_content_type()
                    if content_type not in {"application/json", "text/json"}:
                        fail("api_request_failed")
                    return _bounded_read(response, JSON_LIMIT)
            except contract.F1Error:
                raise
            except HTTPError as error:
                status_code = int(error.code)
                if status_code in {401, 403}:
                    fail("authentication_failed")
                if status_code != 429 and status_code < 500:
                    fail("api_request_failed")
                self._retry_delay(attempt)
            except (URLError, TimeoutError, OSError):
                self._retry_delay(attempt)
        fail("api_request_failed")

    def exact_non_observation_request(
        self, *, route: str, file_name: str, byte_size: int,
    ) -> bytes:
        if byte_size < 0 or byte_size > METADATA_LIMIT:
            fail("metadata_download_failed")
        for attempt in range(ATTEMPTS):
            redirect = MetadataRedirect(file_name)
            checked_route = redirect._checked(route)
            opener = build_opener(redirect)
            request = Request(
                checked_route,
                headers={"Accept": "application/octet-stream", "User-Agent": USER_AGENT},
                method="GET",
            )
            try:
                with opener.open(request, timeout=TIMEOUT_SECONDS) as response:
                    if response.status != 200:
                        fail("metadata_download_failed")
                    final = contract.validated_route(response.geturl())
                    if urlsplit(final).path.rsplit("/", 1)[-1] != file_name:
                        fail("manifest_allowlist_mismatch")
                    return _bounded_read(response, METADATA_LIMIT, byte_size)
            except contract.F1Error:
                raise
            except HTTPError as error:
                status_code = int(error.code)
                if status_code in {401, 403}:
                    fail("metadata_download_failed")
                if status_code != 429 and status_code < 500:
                    fail("metadata_download_failed")
                self._retry_delay(attempt)
            except (URLError, TimeoutError, OSError):
                self._retry_delay(attempt)
        fail("metadata_download_failed")

    def metadata_request(self, record: contract.FileRecord) -> bytes:
        if (
            record.file_role != "metadata_bytes_allowed"
            or record.logical_family not in contract.REQUIRED_METADATA
            or record.route is None
        ):
            fail("raw_payload_output_attempted")
        return self.exact_non_observation_request(
            route=record.route,
            file_name=record.file_name,
            byte_size=record.byte_size,
        )


def crc32c_hex(raw: bytes) -> str:
    crc = 0xFFFFFFFF
    for byte in raw:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ (0x82F63B78 if crc & 1 else 0)
    return f"{(crc ^ 0xFFFFFFFF):08x}"


def _owned_private_dir(path: Path, label: str) -> Path:
    if not path.is_absolute():
        fail("cleanup_incomplete")
    try:
        info = path.lstat()
        resolved = path.resolve(strict=True)
    except OSError:
        fail("cleanup_incomplete")
    if (
        stat.S_ISLNK(info.st_mode)
        or not stat.S_ISDIR(info.st_mode)
        or info.st_uid != os.getuid()
        or stat.S_IMODE(info.st_mode) != 0o700
        or resolved != path
    ):
        fail("cleanup_incomplete")
    forbidden = {Path("/"), Path.home().resolve(), Path.cwd().resolve()}
    if resolved in forbidden or resolved.parent in forbidden:
        fail("cleanup_incomplete")
    if label not in {"raw", "output"}:
        fail("cleanup_incomplete")
    return resolved


def _owned_private_empty_dir(path: Path, label: str) -> Path:
    resolved = _owned_private_dir(path, label)
    if any(resolved.iterdir()):
        fail("cleanup_incomplete")
    return resolved


def _remove_exact_output_files(output_dir: Path) -> None:
    output_dir = _owned_private_dir(output_dir, "output")
    if any(path.name not in OUTPUT_NAMES for path in output_dir.iterdir()):
        fail("cleanup_incomplete")
    for name in OUTPUT_NAMES:
        path = output_dir / name
        try:
            info = path.lstat()
        except FileNotFoundError:
            continue
        except OSError:
            fail("cleanup_incomplete")
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
            fail("cleanup_incomplete")
        try:
            path.unlink()
        except OSError:
            fail("cleanup_incomplete")


def _remove_empty_raw_root(raw_root: Path) -> None:
    if not raw_root.exists():
        return
    checked = _owned_private_empty_dir(raw_root, "raw")
    try:
        checked.rmdir()
    except OSError:
        fail("cleanup_incomplete")


def _write_receipts(output_dir: Path, outputs: dict[str, bytes]) -> None:
    if set(outputs) != set(OUTPUT_NAMES):
        fail("receipt_schema_mismatch")
    written: list[Path] = []
    try:
        for name in OUTPUT_NAMES:
            target = output_dir / name
            flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
            if hasattr(os, "O_NOFOLLOW"):
                flags |= os.O_NOFOLLOW
            descriptor = os.open(target, flags, 0o600)
            try:
                with os.fdopen(descriptor, "wb", closefd=True) as handle:
                    handle.write(outputs[name])
                    handle.flush()
                    os.fsync(handle.fileno())
            except Exception:
                try:
                    os.close(descriptor)
                except OSError:
                    pass
                raise
            written.append(target)
        for target in written:
            info = target.lstat()
            if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode) or stat.S_IMODE(info.st_mode) != 0o600:
                fail("receipt_schema_mismatch")
    except Exception:
        for target in written:
            try:
                target.unlink()
            except OSError:
                pass
        raise


def _query_body() -> bytes:
    value = {
        "productCode": contract.PRODUCT_CODE,
        "siteCodes": list(contract.ROSTER),
        "startDateMonth": contract.REQUEST_START_MONTH,
        "endDateMonth": contract.LAST_ALLOWED_MONTH,
        "release": contract.RELEASE_TAG,
        "package": contract.PACKAGE_TYPE,
        "includeProvisional": False,
    }
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode("ascii")


def _acquire_sanitized_phase(
    *,
    token_box: list[str],
    transport: HTTPTransport,
) -> SanitizedAcquisition:
    """Own every capability/raw object and return only route-free structures."""
    token = ""
    try:
        if len(token_box) != 1:
            fail("authentication_failed")
        token = token_box.pop()
        if (
            not isinstance(token, str)
            or len(token) < 16
            or any(ord(char) < 33 or ord(char) == 127 for char in token)
        ):
            fail("authentication_failed")
        release_raw = transport.api_request(
            method="GET", path=RELEASE_PATH, body=None, token=None,
        )
        release_payload = contract.strict_json_loads(release_raw, max_bytes=JSON_LIMIT)
        release_authority = contract.validate_release_payload(release_payload)
        availability_raw = transport.exact_non_observation_request(
            route=release_authority.availability_route,
            file_name=contract.AVAILABILITY_NAME,
            byte_size=contract.AVAILABILITY_BYTES,
        )
        availability_sha256 = contract.validate_availability_bytes(availability_raw)

        query_raw = transport.api_request(
            method="POST", path=QUERY_PATH, body=_query_body(), token=token,
        )
        # No capability-bearing parsing begins while the environment still owns
        # the API credential.
        os.environ.pop("NEON_TOKEN", None)
        token = ""
        query_payload = contract.strict_json_loads(query_raw, max_bytes=JSON_LIMIT)
        records = contract.validate_query_payload(query_payload)
        downloads = contract.unique_metadata_downloads(records)
        metadata_payloads: dict[str, tuple[contract.FileRecord, bytes]] = {}
        for record in downloads:
            raw = transport.metadata_request(record)
            if (
                len(raw) != record.byte_size
                or contract.md5_bytes(raw) != record.md5
                or crc32c_hex(raw) != record.crc32c
            ):
                fail("manifest_allowlist_mismatch")
            metadata_payloads[record.logical_family] = (record, raw)
        schema_rows = contract.inspect_metadata(metadata_payloads)
        sanitized = SanitizedAcquisition(
            availability_sha256=availability_sha256,
            records=tuple(replace(record, route=None) for record in records),
            schema_rows=tuple(dict(row) for row in schema_rows),
        )
        if any(record.route is not None for record in sanitized.records):
            fail("cleanup_incomplete")
        if any(
            isinstance(value, (bytes, bytearray, memoryview))
            for row in sanitized.schema_rows
            for value in row.values()
        ):
            fail("cleanup_incomplete")
        return sanitized
    finally:
        token = ""
        os.environ.pop("NEON_TOKEN", None)


def acquire(
    *,
    output_dir: Path,
    raw_root: Path,
    expected_source_sha: str,
    token_box: list[str],
    transport: HTTPTransport,
    repo_root: Path,
) -> None:
    if contract.HEX40.fullmatch(expected_source_sha) is None:
        fail("revision_identity_mismatch")
    output_dir = _owned_private_empty_dir(output_dir, "output")
    raw_root = _owned_private_empty_dir(raw_root, "raw")
    if output_dir == raw_root or output_dir.parent != raw_root.parent:
        fail("cleanup_incomplete")

    ledger = contract.verify_ledger(repo_root / "docs/receipts/discharge-inverts-response-site-years.tsv")
    driver_hashes = contract.verify_driver_hashes(repo_root)
    sanitized = _acquire_sanitized_phase(
        token_box=token_box,
        transport=transport,
    )
    # The raw-phase frame has returned and been destroyed.  Only the immutable,
    # route-free result exists when cleanup and receipt construction begin.
    gc.collect()
    _remove_empty_raw_root(raw_root)

    outputs = contract.build_receipt_bytes(
        source_sha=expected_source_sha,
        availability_sha256=sanitized.availability_sha256,
        records=sanitized.records,
        schema_rows=sanitized.schema_rows,
        ledger_receipt=ledger,
        driver_hashes=driver_hashes,
    )
    _write_receipts(output_dir, outputs)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--raw-root", required=True)
    parser.add_argument("--expected-source-sha", required=True)
    return parser.parse_args(argv)


def _cancelled(signum, frame):
    del signum, frame
    fail("acquisition_cancelled")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN"):
        fail("credential_or_capability_exposed")
    token_box = [os.environ.pop("NEON_TOKEN", "")]
    output_dir = Path(args.output_dir)
    raw_root = Path(args.raw_root)
    for handled in (signal.SIGINT, signal.SIGTERM):
        signal.signal(handled, _cancelled)
    try:
        acquire(
            output_dir=output_dir,
            raw_root=raw_root,
            expected_source_sha=args.expected_source_sha,
            token_box=token_box,
            transport=HTTPTransport(),
            repo_root=Path.cwd().resolve(),
        )
        token_box.clear()
        return 0
    except contract.F1Error as error:
        token_box.clear()
        try:
            _remove_exact_output_files(output_dir.resolve(strict=True))
        except (contract.F1Error, OSError):
            error = contract.F1Error("cleanup_incomplete")
        try:
            _remove_empty_raw_root(raw_root.resolve(strict=True))
        except FileNotFoundError:
            pass
        except (contract.F1Error, OSError):
            error = contract.F1Error("cleanup_incomplete")
        print(f"FAIL_CLOSED:{error.code}", file=sys.stderr)
        return 1
    except Exception:
        token_box.clear()
        code = "unexpected_internal_error"
        try:
            _remove_exact_output_files(output_dir.resolve(strict=True))
        except (contract.F1Error, OSError, FileNotFoundError):
            code = "cleanup_incomplete"
        try:
            _remove_empty_raw_root(raw_root.resolve(strict=True))
        except FileNotFoundError:
            pass
        except (contract.F1Error, OSError):
            code = "cleanup_incomplete"
        print(f"FAIL_CLOSED:{code}", file=sys.stderr)
        return 1
    finally:
        os.environ.pop("NEON_TOKEN", None)


if __name__ == "__main__":
    raise SystemExit(main())
