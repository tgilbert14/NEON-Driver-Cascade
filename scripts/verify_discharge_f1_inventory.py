#!/usr/bin/env python3
"""Independently verify a sanitized Continuous Discharge F1 receipt family.

The verifier is deliberately separate from the acquisition/producer module.  It
uses only the Python standard library, performs no network or subprocess work,
and treats the supplied directory as an immutable four-file review surface.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
from typing import NoReturn, Sequence


CONTRACT_VERSION = "discharge-feasibility-f1-v1"
GATE = "F1_METADATA_INVENTORY"

F0_AUTHORITY_MERGE = "b75996a85809ed0cd8ba89121e0de18e22063cc7"
F0_AUTHORITY_TREE = "8e7b774da4fc8486fb3c41e790317c61d5af9379"
SPEC_PATH = "docs/DISCHARGE-FEASIBILITY-SPEC.md"
SPEC_BLOB = "643dbaa3489bb8100de691b2de0ead124f842502"
SPEC_SHA256 = "831baf97f6558a7d0bccacb401880929ffccd7a6ebf210b8ee70d536db298ac7"

PRODUCT_CODE = "DP4.00130.001"
PACKAGE_TYPE = "expanded"
RELEASE_TAG = "RELEASE-2026"
RELEASE_UUID = "c28725ff-5aa2-41fa-845e-a7f1c8239d09"
RELEASE_GENERATION_UTC = "2026-01-23T00:07:49Z"
PRODUCT_DOI = "10.48443/4n6c-gc44"
AVAILABILITY_NAME = "manifest-available-20260123T000738Z.json"
AVAILABILITY_BYTES = 2_779_477
AVAILABILITY_MD5 = "33c04c0f24dba030d3082acf704e2c56"
REQUEST_START_MONTH = "2016-08"
LAST_ALLOWED_MONTH = "2024-09"
REQUEST_START_UTC = "2016-08-01T00:00:00Z"
REQUEST_END_UTC = "2024-09-30T23:59:59Z"

LEDGER_PATH = "docs/receipts/discharge-inverts-response-site-years.tsv"
LEDGER_BLOB = "c2aefd1aa7db8b1d7de4bf0551b1c95cba73f7a8"
LEDGER_SHA256 = "79bb45911ab734ffc64444f248ac17ca42a78005707657fbe16effaef25e5296"
LEDGER_ROWS = 210
LEDGER_SITES = 24
LEDGER_SITES_GE_6 = 23

ROSTER = (
    "ARIK", "BIGC", "BLDE", "BLUE", "CARI", "COMO", "CUPE", "GUIL",
    "HOPB", "KING", "LECO", "LEWI", "MART", "MAYF", "MCDI", "MCRA",
    "OKSR", "POSE", "PRIN", "REDB", "SYCA", "TECR", "WALK", "WLOU",
)
ROSTER_SET = frozenset(ROSTER)
EXCLUDED_SITES = frozenset({"TOMB", "TOOK"})

MAIN_TABLES = ("csd_15_min", "csd_continuousDischarge")
MAIN_TABLE_SET = frozenset(MAIN_TABLES)
SPECIAL_TABLE = "csd_continuousDischargeUSGS"
KNOWN_OTHER_TABLES = frozenset({
    "sdrc_gaugePressureRelationship",
    "csd_gaugeWaterColumnRegression",
    "csd_dataGapToFillMethodMapping",
    "csd_constantBiasShift",
    "csd_gapFillingRegression",
    "csd_dischargeRegressionUSGS",
    "geo_gaugeWaterColumnRegression",
    "bat_gaugeWaterColumnRegression",
    "bat_dischargeRegressionUSGS",
})

REQUIRED_METADATA = (
    "variables_00130",
    "validation_00130",
    "categoricalCodes_00130",
    "readme_00130",
    "issueLog_00130",
)
REQUIRED_METADATA_SET = frozenset(REQUIRED_METADATA)
IDENTITY_ONLY_METADATA = (
    "science_review_flags_00130",
    "sensor_positions_00130",
    "citation_00130_RELEASE-2026",
)
ALL_METADATA = REQUIRED_METADATA + IDENTITY_ONLY_METADATA

METADATA_HEADERS = {
    "variables_00130": (
        "table", "fieldName", "description", "dataType", "units",
        "downloadPkg", "pubFormat", "primaryKey", "categoricalCodeName",
    ),
    "validation_00130": (
        "table", "fieldName", "description", "dataType", "units",
        "parserToCreate", "entryValidationRulesParser",
        "entryValidationRulesForm",
    ),
    "categoricalCodes_00130": (
        "name", "pubCode", "description", "startDate", "endDate",
    ),
    "issueLog_00130": (
        "id", "parentIssueID", "issueDate", "resolvedDate", "dateRangeStart",
        "dateRangeEnd", "locationAffected", "issue", "resolution",
    ),
    "readme_00130": (),
}

REQUIRED_FIELDS = {
    "csd_15_min": (
        "siteID", "namedLocation", "endDateTime", "dischargeContinuous",
        "dischargeFinalQF", "dischargeFinalQFSciRvw",
        "dischargeCorrectionApplied",
    ),
    "csd_continuousDischarge": (
        "siteID", "namedLocation", "endDate", "maxpostDischarge",
        "dischargeFinalQF", "dischargeFinalQFSciRvw",
    ),
}
QC_FIELD_KEYS = frozenset({
    ("csd_15_min", "dischargeFinalQF"),
    ("csd_15_min", "dischargeFinalQFSciRvw"),
    ("csd_15_min", "dischargeCorrectionApplied"),
    ("csd_continuousDischarge", "dischargeFinalQF"),
    ("csd_continuousDischarge", "dischargeFinalQFSciRvw"),
})

CANONICAL_DRIVER_PATHS = {
    "cascade": "data/cascade.rds",
    "search": "data/search_index.rds",
    "meta": "data/cascade_meta.rds",
    "codebook": "data/neon-cascade-codebook.csv",
    "manifest": "manifest.json",
}
CANONICAL_DRIVER_HASHES = {
    "cascade": "47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe",
    "search": "a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e",
    "meta": "00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de",
    "codebook": "a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3",
    "manifest": "92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79",
}

RECEIPT_NAME = "discharge-f1-release-receipt.json"
FILE_INVENTORY_NAME = "discharge-f1-file-inventory.tsv"
SCHEMA_INVENTORY_NAME = "discharge-f1-schema-inventory.tsv"
ALLOWLIST_NAME = "discharge-f2-file-allowlist.tsv"
OUTPUT_NAMES = frozenset({
    RECEIPT_NAME,
    FILE_INVENTORY_NAME,
    SCHEMA_INVENTORY_NAME,
    ALLOWLIST_NAME,
})

FILE_INVENTORY_COLUMNS = (
    "release", "package_type", "domain_code", "package_generation_utc",
    "site_id", "year_month", "file_role", "logical_family", "file_name",
    "file_generation_utc", "byte_size", "md5", "crc32c",
)
ALLOWLIST_COLUMNS = (
    "release", "package_type", "domain_code", "package_generation_utc",
    "site_id", "year_month", "table_family", "file_name",
    "file_generation_utc", "byte_size", "md5", "crc32c",
)
SCHEMA_COLUMNS = (
    "record_kind", "metadata_family", "file_name", "metadata_sha256",
    "metadata_row_count", "metadata_columns_sha256", "table_name",
    "field_name", "declared_data_type", "declared_units",
    "declared_download_package", "declared_publication_format",
    "declared_primary_key", "declared_categorical_code",
    "validation_parser", "validation_rule_parser", "validation_rule_form",
    "categorical_pub_code", "categorical_start_date", "categorical_end_date",
)
SCHEMA_DETAIL_KINDS = {
    "variables_00130": "field_declaration",
    "validation_00130": "validation_rule",
    "categoricalCodes_00130": "categorical_code",
}

HEX32 = re.compile(r"^[0-9a-f]{32}$")
HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
CRC32C = re.compile(r"^[0-9a-f]{8}$")
MONTH = re.compile(r"^(?:19|20)[0-9]{2}-(?:0[1-9]|1[0-2])$")
YEAR = re.compile(r"^(?:19|20)[0-9]{2}$")
DOMAIN = re.compile(r"^D[0-9]{2}$")
COMPACT_UTC = re.compile(r"^20[0-9]{6}T[0-9]{6}Z$")
UTC_INSTANT = re.compile(
    r"^20[0-9]{2}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])"
    r"T(?:[01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"
)
CALENDAR_DATE = re.compile(
    r"^20[0-9]{2}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])$"
)
NONNEGATIVE_INTEGER = re.compile(r"^(?:0|[1-9][0-9]*)$")
BASENAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,254}$")
OTHER_OBSERVATION = re.compile(r"^(?:csd|sdrc|geo|bat)_[A-Za-z0-9_]+$")

MAX_JSON_BYTES = 1024 * 1024
MAX_TSV_BYTES = 64 * 1024 * 1024
READ_CHUNK = 1024 * 1024

FORBIDDEN_ROUTE_MARKERS = (
    b"http://",
    b"https://",
    b"x-api-token",
    b"authorization",
    b"bearer ",
    b"x-amz-",
    b"googleaccessid",
    b"signature=",
    b"credential=",
    b"neon_token",
    b"access_token",
    b"api_key",
)


class VerificationError(RuntimeError):
    """A bounded, non-sensitive verifier failure."""

    def __init__(self, code: str):
        if re.fullmatch(r"[a-z0-9_]+", code) is None:
            code = "unexpected_internal_error"
        super().__init__(code)
        self.code = code


def fail(code: str) -> NoReturn:
    raise VerificationError(code)


def sha256_bytes(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def git_blob_sha1(raw: bytes) -> str:
    prefix = b"blob " + str(len(raw)).encode("ascii") + b"\x00"
    return hashlib.sha1(prefix + raw).hexdigest()


def canonical_json(value: object) -> bytes:
    try:
        text = json.dumps(value, sort_keys=True, indent=2, ensure_ascii=True)
    except (TypeError, ValueError):
        fail("receipt_schema_mismatch")
    return (text + "\n").encode("ascii")


def _reject_duplicate_keys(pairs: list[tuple[str, object]]) -> dict[str, object]:
    output: dict[str, object] = {}
    for key, value in pairs:
        if key in output:
            fail("duplicate_json_key")
        output[key] = value
    return output


def strict_json(raw: bytes) -> dict[str, object]:
    if not raw or len(raw) > MAX_JSON_BYTES:
        fail("malformed_or_oversized_json")
    try:
        text = raw.decode("ascii")
        value = json.loads(
            text,
            object_pairs_hook=_reject_duplicate_keys,
            parse_constant=lambda _value: fail("forbidden_json_constant"),
        )
    except (UnicodeDecodeError, json.JSONDecodeError):
        fail("malformed_json")
    if not isinstance(value, dict):
        fail("malformed_json")
    return value


def _exact_mapping(value: object, keys: set[str]) -> dict[str, object]:
    if not isinstance(value, dict) or set(value) != keys:
        fail("receipt_schema_mismatch")
    return value


def _assert_route_free(raw: bytes) -> None:
    lowered = raw.lower()
    if any(marker in lowered for marker in FORBIDDEN_ROUTE_MARKERS):
        fail("credential_or_capability_exposed")
    if b"?" in raw or b"\\u003f" in lowered:
        fail("credential_or_capability_exposed")


def _read_exact_receipt_family(directory: Path) -> dict[str, bytes]:
    try:
        path_info = directory.lstat()
    except OSError:
        fail("receipt_surface_mismatch")
    if (
        stat.S_ISLNK(path_info.st_mode)
        or not stat.S_ISDIR(path_info.st_mode)
        or path_info.st_uid != os.getuid()
        or stat.S_IMODE(path_info.st_mode) != 0o700
    ):
        fail("receipt_permissions_mismatch")

    flags = os.O_RDONLY
    if hasattr(os, "O_DIRECTORY"):
        flags |= os.O_DIRECTORY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        directory_fd = os.open(directory, flags)
    except OSError:
        fail("receipt_surface_mismatch")
    try:
        opened_info = os.fstat(directory_fd)
        if (
            not stat.S_ISDIR(opened_info.st_mode)
            or (opened_info.st_dev, opened_info.st_ino)
            != (path_info.st_dev, path_info.st_ino)
        ):
            fail("receipt_surface_mismatch")
        try:
            names = os.listdir(directory_fd)
        except OSError:
            fail("receipt_surface_mismatch")
        if len(names) != len(OUTPUT_NAMES) or set(names) != OUTPUT_NAMES:
            fail("receipt_surface_mismatch")

        output: dict[str, bytes] = {}
        for name in sorted(OUTPUT_NAMES):
            try:
                before = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
            except OSError:
                fail("receipt_surface_mismatch")
            mode = stat.S_IMODE(before.st_mode)
            if (
                not stat.S_ISREG(before.st_mode)
                or before.st_uid != os.getuid()
                or mode not in {0o600, 0o644}
            ):
                fail("receipt_permissions_mismatch")
            file_flags = os.O_RDONLY
            if hasattr(os, "O_NOFOLLOW"):
                file_flags |= os.O_NOFOLLOW
            try:
                descriptor = os.open(name, file_flags, dir_fd=directory_fd)
            except OSError:
                fail("receipt_surface_mismatch")
            try:
                after = os.fstat(descriptor)
                if (
                    not stat.S_ISREG(after.st_mode)
                    or (after.st_dev, after.st_ino) != (before.st_dev, before.st_ino)
                    or stat.S_IMODE(after.st_mode) != mode
                    or after.st_size < 1
                    or after.st_size > MAX_TSV_BYTES
                ):
                    fail("receipt_surface_mismatch")
                chunks: list[bytes] = []
                remaining = after.st_size
                while remaining:
                    chunk = os.read(descriptor, min(READ_CHUNK, remaining))
                    if not chunk:
                        fail("receipt_surface_mismatch")
                    chunks.append(chunk)
                    remaining -= len(chunk)
                if os.read(descriptor, 1):
                    fail("receipt_surface_mismatch")
                final_info = os.fstat(descriptor)
                if (
                    (final_info.st_dev, final_info.st_ino, final_info.st_size)
                    != (after.st_dev, after.st_ino, after.st_size)
                    or final_info.st_mtime_ns != after.st_mtime_ns
                ):
                    fail("receipt_surface_mismatch")
                output[name] = b"".join(chunks)
            finally:
                os.close(descriptor)
        return output
    finally:
        os.close(directory_fd)


def parse_tsv(
    raw: bytes,
    columns: Sequence[str],
) -> list[dict[str, str]]:
    if not raw or len(raw) > MAX_TSV_BYTES:
        fail("malformed_or_oversized_tsv")
    if not raw.endswith(b"\n") or b"\r" in raw or b"\x00" in raw:
        fail("malformed_tsv")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        fail("malformed_tsv")
    if text.startswith("\ufeff"):
        fail("malformed_tsv")
    lines = text[:-1].split("\n")
    if not lines or tuple(lines[0].split("\t")) != tuple(columns):
        fail("tsv_schema_mismatch")
    rows: list[dict[str, str]] = []
    for line in lines[1:]:
        values = line.split("\t")
        if len(values) != len(columns):
            fail("tsv_schema_mismatch")
        rows.append(dict(zip(columns, values)))
    rebuilt = "\n".join(
        ["\t".join(columns)]
        + ["\t".join(row[column] for column in columns) for row in rows]
    ) + "\n"
    if rebuilt.encode("utf-8") != raw:
        fail("malformed_tsv")
    return rows


def _canonical_tsv(
    columns: Sequence[str],
    rows: Sequence[dict[str, str]],
) -> bytes:
    for row in rows:
        if set(row) != set(columns):
            fail("tsv_schema_mismatch")
    text = "\n".join(
        ["\t".join(columns)]
        + ["\t".join(row[column] for column in columns) for row in rows]
    ) + "\n"
    return text.encode("utf-8")


def _validate_basename(name: str) -> tuple[str, ...]:
    if BASENAME.fullmatch(name) is None:
        fail("inventory_contract_mismatch")
    if (
        name in {".", ".."}
        or ".." in name
        or any(char in name for char in "/\\%?#:@")
        or any(char.isspace() for char in name)
    ):
        fail("inventory_contract_mismatch")
    try:
        name.encode("ascii")
    except UnicodeEncodeError:
        fail("inventory_contract_mismatch")
    tokens = tuple(name.split("."))
    if any(not token for token in tokens):
        fail("inventory_contract_mismatch")
    product_tokens = ("DP4", "00130", "001")
    matches = sum(
        tokens[index:index + 3] == product_tokens
        for index in range(max(0, len(tokens) - 2))
    )
    if matches != 1:
        fail("inventory_contract_mismatch")
    return tokens


def _validated_utc(value: str, code: str) -> str:
    if UTC_INSTANT.fullmatch(value) is None:
        fail(code)
    try:
        datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc,
        )
    except ValueError:
        fail(code)
    return value


def _compact_utc(value: str) -> str:
    if COMPACT_UTC.fullmatch(value) is None:
        fail("inventory_contract_mismatch")
    try:
        parsed = datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(
            tzinfo=timezone.utc,
        )
    except ValueError:
        fail("inventory_contract_mismatch")
    return parsed.strftime("%Y-%m-%dT%H:%M:%SZ")


def _reject_family_near_match(family: str) -> None:
    for exact in ALL_METADATA + MAIN_TABLES + (SPECIAL_TABLE,):
        if family != exact and (
            family.lower() == exact.lower()
            or family.startswith(exact + "_")
            or family.startswith(exact + "-")
        ):
            fail("inventory_contract_mismatch")


def _classify_name(
    name: str,
    domain: str,
    site: str,
    month: str,
    package_generation: str,
) -> tuple[str, str, str]:
    tokens = _validate_basename(name)
    if DOMAIN.fullmatch(domain) is None or site not in ROSTER_SET:
        fail("inventory_contract_mismatch")
    if MONTH.fullmatch(month) is None or not (
        REQUEST_START_MONTH <= month <= LAST_ALLOWED_MONTH
    ):
        fail("inventory_contract_mismatch")
    package_generation = _validated_utc(
        package_generation, "inventory_contract_mismatch",
    )
    if (
        package_generation > RELEASE_GENERATION_UTC
        or package_generation[:7] < month
    ):
        fail("inventory_contract_mismatch")

    if len(tokens) in {6, 7} and tokens[:4] == ("NEON", "DP4", "00130", "001"):
        family = tokens[4]
        _reject_family_near_match(family)
        if family in ALL_METADATA:
            extensions = {"csv"}
            if family in {"readme_00130", "citation_00130_RELEASE-2026"}:
                extensions = {"csv", "txt"}
            if tokens[-1] not in extensions:
                fail("inventory_contract_mismatch")
            file_generation = ""
            if len(tokens) == 7:
                file_generation = _compact_utc(tokens[5])
                if file_generation > RELEASE_GENERATION_UTC:
                    fail("inventory_contract_mismatch")
            role = (
                "metadata_bytes_allowed"
                if family in REQUIRED_METADATA_SET
                else "metadata_identity_only"
            )
            return role, family, file_generation

    if len(tokens) != 11:
        fail("inventory_contract_mismatch")
    (
        neon, file_domain, file_site, dp_level, product, revision, family,
        file_month, file_package, compact_generation, extension,
    ) = tokens
    _reject_family_near_match(family)
    if (
        neon != "NEON"
        or file_domain != domain
        or file_site != site
        or (dp_level, product, revision) != ("DP4", "00130", "001")
        or file_month != month
        or file_package != PACKAGE_TYPE
        or extension != "csv"
        or any(token in EXCLUDED_SITES for token in tokens)
    ):
        fail("inventory_contract_mismatch")
    file_generation = _compact_utc(compact_generation)
    if file_generation > package_generation or file_generation[:7] < month:
        fail("inventory_contract_mismatch")
    if family in MAIN_TABLE_SET:
        return "f2_identity_only", family, file_generation
    if family == SPECIAL_TABLE:
        return "known_special_excluded", family, file_generation
    if family in KNOWN_OTHER_TABLES or OTHER_OBSERVATION.fullmatch(family):
        return "other_observation_excluded", family, file_generation
    fail("inventory_contract_mismatch")


def validate_file_inventory(rows: list[dict[str, str]]) -> None:
    if not rows:
        fail("inventory_contract_mismatch")
    expected_order = sorted(
        rows,
        key=lambda row: (
            row["site_id"],
            row["year_month"],
            row["domain_code"],
            row["package_generation_utc"],
            row["file_role"],
            row["logical_family"],
            row["file_name"],
            row["file_generation_utc"],
            row["md5"],
            row["crc32c"],
        ),
    )
    if rows != expected_order:
        fail("inventory_sort_mismatch")

    source_keys: set[tuple[str, str, str]] = set()
    package_contexts: dict[tuple[str, str], tuple[str, str]] = {}
    complete_rows: set[tuple[str, ...]] = set()
    metadata_identities: dict[str, set[tuple[str, str, str, str]]] = {
        family: set() for family in REQUIRED_METADATA
    }
    for row in rows:
        if row["release"] != RELEASE_TAG or row["package_type"] != PACKAGE_TYPE:
            fail("inventory_contract_mismatch")
        site = row["site_id"]
        month = row["year_month"]
        domain = row["domain_code"]
        package_generation = row["package_generation_utc"]
        if (
            site not in ROSTER_SET
            or site in EXCLUDED_SITES
            or DOMAIN.fullmatch(domain) is None
            or MONTH.fullmatch(month) is None
            or month < REQUEST_START_MONTH
            or month > LAST_ALLOWED_MONTH
        ):
            fail("inventory_contract_mismatch")
        if NONNEGATIVE_INTEGER.fullmatch(row["byte_size"]) is None:
            fail("inventory_contract_mismatch")
        if HEX32.fullmatch(row["md5"]) is None or CRC32C.fullmatch(row["crc32c"]) is None:
            fail("inventory_contract_mismatch")
        package_key = (site, month)
        package_context = (domain, package_generation)
        prior_context = package_contexts.get(package_key)
        if prior_context is not None and prior_context != package_context:
            fail("inventory_contract_mismatch")
        package_contexts[package_key] = package_context
        expected_role, expected_family, expected_file_generation = _classify_name(
            row["file_name"], domain, site, month, package_generation,
        )
        if (
            row["file_role"] != expected_role
            or row["logical_family"] != expected_family
            or row["file_generation_utc"] != expected_file_generation
        ):
            fail("inventory_contract_mismatch")
        key = (site, month, row["file_name"])
        if key in source_keys:
            fail("inventory_duplicate")
        source_keys.add(key)
        serialized = tuple(row[column] for column in FILE_INVENTORY_COLUMNS)
        if serialized in complete_rows:
            fail("inventory_duplicate")
        complete_rows.add(serialized)
        if expected_role == "metadata_bytes_allowed":
            metadata_identities[expected_family].add((
                row["file_name"], row["byte_size"], row["md5"], row["crc32c"],
            ))

    for family in REQUIRED_METADATA:
        if len(metadata_identities[family]) != 1:
            fail("required_metadata_mismatch")
    if not MAIN_TABLE_SET.issubset({row["logical_family"] for row in rows}):
        fail("required_table_missing")


def expected_allowlist_rows(
    inventory_rows: list[dict[str, str]],
) -> list[dict[str, str]]:
    output: list[dict[str, str]] = []
    for row in inventory_rows:
        if row["file_role"] != "f2_identity_only":
            continue
        output.append({
            "release": row["release"],
            "package_type": row["package_type"],
            "domain_code": row["domain_code"],
            "package_generation_utc": row["package_generation_utc"],
            "site_id": row["site_id"],
            "year_month": row["year_month"],
            "table_family": row["logical_family"],
            "file_name": row["file_name"],
            "file_generation_utc": row["file_generation_utc"],
            "byte_size": row["byte_size"],
            "md5": row["md5"],
            "crc32c": row["crc32c"],
        })
    return output


def validate_allowlist(
    rows: list[dict[str, str]],
    inventory_rows: list[dict[str, str]],
) -> None:
    expected = expected_allowlist_rows(inventory_rows)
    if rows != expected or not rows:
        fail("allowlist_contract_mismatch")
    if {row["table_family"] for row in rows} != MAIN_TABLE_SET:
        fail("allowlist_contract_mismatch")
    identities: set[tuple[str, str, str]] = set()
    for row in rows:
        if (
            row["table_family"] not in MAIN_TABLE_SET
            or row["site_id"] in EXCLUDED_SITES
            or "USGS" in row["table_family"]
            or "TOMB" in row["file_name"].split(".")
            or "TOOK" in row["file_name"].split(".")
        ):
            fail("allowlist_contract_mismatch")
        identity = (row["site_id"], row["year_month"], row["file_name"])
        if identity in identities:
            fail("allowlist_contract_mismatch")
        identities.add(identity)


def _columns_digest(header: Sequence[str]) -> str:
    raw = b"" if not header else ("\t".join(header) + "\n").encode("utf-8")
    return sha256_bytes(raw)


def _valid_schema_date(value: str) -> bool:
    if not value:
        return True
    if CALENDAR_DATE.fullmatch(value) is None:
        return False
    try:
        datetime.strptime(value, "%Y-%m-%d")
    except ValueError:
        return False
    return True


def validate_schema_inventory(
    rows: list[dict[str, str]],
    inventory_rows: list[dict[str, str]],
) -> None:
    if not rows:
        fail("schema_contract_mismatch")
    expected_order = sorted(
        rows,
        key=lambda row: tuple(row[column] for column in SCHEMA_COLUMNS),
    )
    if rows != expected_order:
        fail("schema_sort_mismatch")
    serialized = [tuple(row[column] for column in SCHEMA_COLUMNS) for row in rows]
    if len(serialized) != len(set(serialized)):
        fail("schema_duplicate")

    metadata_inventory: dict[str, set[str]] = {
        family: set() for family in REQUIRED_METADATA
    }
    for row in inventory_rows:
        if row["file_role"] == "metadata_bytes_allowed":
            metadata_inventory[row["logical_family"]].add(row["file_name"])

    metadata_rows: dict[str, dict[str, str]] = {}
    declarations: dict[tuple[str, str], dict[str, str]] = {}
    validation_rows: list[dict[str, str]] = []
    categorical_rows: list[dict[str, str]] = []
    detail_columns = SCHEMA_COLUMNS[6:]
    common_detail_empty = ("metadata_row_count", "metadata_columns_sha256")
    declaration_tail_empty = (
        "validation_parser", "validation_rule_parser", "validation_rule_form",
        "categorical_pub_code", "categorical_start_date", "categorical_end_date",
    )
    for row in rows:
        kind = row["record_kind"]
        if kind == "metadata_file":
            family = row["metadata_family"]
            if family not in REQUIRED_METADATA_SET or family in metadata_rows:
                fail("schema_contract_mismatch")
            if (
                row["file_name"] not in metadata_inventory[family]
                or HEX64.fullmatch(row["metadata_sha256"]) is None
                or NONNEGATIVE_INTEGER.fullmatch(row["metadata_row_count"]) is None
                or row["metadata_columns_sha256"]
                != _columns_digest(METADATA_HEADERS[family])
                or any(row[column] for column in detail_columns)
            ):
                fail("schema_contract_mismatch")
            if family == "readme_00130" and row["metadata_row_count"] != "0":
                fail("schema_contract_mismatch")
            metadata_rows[family] = row
            continue

        if (
            any(row[column] for column in common_detail_empty)
            or HEX64.fullmatch(row["metadata_sha256"]) is None
        ):
            fail("schema_contract_mismatch")

        if kind == "field_declaration":
            if (
                row["metadata_family"] != "variables_00130"
                or not row["table_name"]
                or not row["field_name"]
                or not row["declared_data_type"]
                or row["declared_download_package"] not in {"basic", "expanded"}
                or row["declared_primary_key"] not in {"", "Y", "N"}
                or any(row[column] for column in declaration_tail_empty)
            ):
                fail("schema_contract_mismatch")
            key = (row["table_name"], row["field_name"])
            if key in declarations:
                fail("schema_duplicate")
            declarations[key] = row
            continue

        if kind == "validation_rule":
            if (
                row["metadata_family"] != "validation_00130"
                or not row["table_name"]
                or not row["field_name"]
                or not row["declared_data_type"]
                or row["declared_download_package"]
                or row["declared_publication_format"]
                or row["declared_primary_key"]
                or row["declared_categorical_code"]
                or not any(row[column] for column in (
                    "validation_parser", "validation_rule_parser",
                    "validation_rule_form",
                ))
                or any(row[column] for column in (
                    "categorical_pub_code", "categorical_start_date",
                    "categorical_end_date",
                ))
            ):
                fail("schema_contract_mismatch")
            validation_rows.append(row)
            continue

        if kind == "categorical_code":
            if (
                row["metadata_family"] != "categoricalCodes_00130"
                or row["table_name"]
                or row["field_name"]
                or row["declared_data_type"]
                or row["declared_units"]
                or row["declared_download_package"]
                or row["declared_publication_format"]
                or row["declared_primary_key"]
                or not row["declared_categorical_code"]
                or any(row[column] for column in (
                    "validation_parser", "validation_rule_parser",
                    "validation_rule_form",
                ))
                or not row["categorical_pub_code"]
                or not _valid_schema_date(row["categorical_start_date"])
                or not _valid_schema_date(row["categorical_end_date"])
                or (
                    row["categorical_start_date"]
                    and row["categorical_end_date"]
                    and row["categorical_start_date"] > row["categorical_end_date"]
                )
            ):
                fail("schema_contract_mismatch")
            categorical_rows.append(row)
            continue

        fail("schema_contract_mismatch")

    if set(metadata_rows) != REQUIRED_METADATA_SET:
        fail("required_metadata_mismatch")
    detail_by_family = {
        "variables_00130": list(declarations.values()),
        "validation_00130": validation_rows,
        "categoricalCodes_00130": categorical_rows,
    }
    for family, detail_rows in detail_by_family.items():
        metadata = metadata_rows[family]
        if int(metadata["metadata_row_count"]) != len(detail_rows):
            fail("schema_contract_mismatch")
        for row in detail_rows:
            if (
                row["file_name"] != metadata["file_name"]
                or row["metadata_sha256"] != metadata["metadata_sha256"]
            ):
                fail("schema_contract_mismatch")

    for row in declarations.values():
        if (
            row["file_name"] != metadata_rows["variables_00130"]["file_name"]
            or row["metadata_sha256"]
            != metadata_rows["variables_00130"]["metadata_sha256"]
        ):
            fail("schema_contract_mismatch")
    if not declarations:
        fail("required_field_missing")
    for table, fields in REQUIRED_FIELDS.items():
        for field in fields:
            if (table, field) not in declarations:
                fail("required_field_missing")

    for row in validation_rows:
        if (row["table_name"], row["field_name"]) not in declarations:
            fail("schema_contract_mismatch")
    referenced_categorical = {
        row["declared_categorical_code"]
        for row in declarations.values()
        if row["declared_categorical_code"]
    }
    emitted_categorical = {
        row["declared_categorical_code"] for row in categorical_rows
    }
    if not referenced_categorical.issubset(emitted_categorical):
        fail("schema_contract_mismatch")
    validation_keys = {
        (row["table_name"], row["field_name"]) for row in validation_rows
    }
    categorical_keys = {
        key for key, row in declarations.items()
        if row["declared_categorical_code"]
    }
    if not QC_FIELD_KEYS.issubset(validation_keys | categorical_keys):
        fail("schema_contract_mismatch")


def expected_schema_detail(
    schema_rows: list[dict[str, str]],
) -> dict[str, dict[str, object]]:
    metadata_rows = {
        row["metadata_family"]: row
        for row in schema_rows
        if row["record_kind"] == "metadata_file"
    }
    output: dict[str, dict[str, object]] = {}
    for family, record_kind in SCHEMA_DETAIL_KINDS.items():
        metadata = metadata_rows.get(family)
        if metadata is None:
            fail("schema_contract_mismatch")
        detail_rows = [
            row for row in schema_rows
            if row["record_kind"] == record_kind
            and row["metadata_family"] == family
        ]
        metadata_count = int(metadata["metadata_row_count"])
        if len(detail_rows) != metadata_count:
            fail("schema_contract_mismatch")
        output[family] = {
            "record_kind": record_kind,
            "metadata_sha256": metadata["metadata_sha256"],
            "metadata_row_count": metadata_count,
            "detail_row_count": len(detail_rows),
            "detail_sha256": sha256_bytes(
                _canonical_tsv(SCHEMA_COLUMNS, detail_rows),
            ),
        }
    return output


def expected_receipt(
    *,
    source_sha: str,
    availability_sha256: str,
    file_inventory_raw: bytes,
    file_inventory_rows: list[dict[str, str]],
    schema_raw: bytes,
    schema_rows: list[dict[str, str]],
    allowlist_raw: bytes,
    allowlist_rows: list[dict[str, str]],
) -> dict[str, object]:
    roster_digest = sha256_bytes(("\n".join(ROSTER) + "\n").encode("ascii"))
    excluded_count = sum(
        row["file_role"] in {
            "other_observation_excluded", "known_special_excluded",
        }
        for row in file_inventory_rows
    )
    return {
        "schema_version": CONTRACT_VERSION,
        "gate": GATE,
        "source_sha": source_sha,
        "f0_authority": {
            "merge": F0_AUTHORITY_MERGE,
            "tree": F0_AUTHORITY_TREE,
            "spec_blob": SPEC_BLOB,
            "spec_sha256": SPEC_SHA256,
        },
        "release": {
            "tag": RELEASE_TAG,
            "uuid": RELEASE_UUID,
            "generation_utc": RELEASE_GENERATION_UTC,
            "doi": PRODUCT_DOI,
            "package_type": PACKAGE_TYPE,
            "availability_manifest_name": AVAILABILITY_NAME,
            "availability_manifest_byte_size": AVAILABILITY_BYTES,
            "availability_manifest_md5": AVAILABILITY_MD5,
            "availability_manifest_sha256": availability_sha256,
        },
        "request": {
            "product_code": PRODUCT_CODE,
            "site_count": len(ROSTER),
            "site_roster_sha256": roster_digest,
            "start_month": REQUEST_START_MONTH,
            "end_month": LAST_ALLOWED_MONTH,
            "start_utc": REQUEST_START_UTC,
            "end_utc": REQUEST_END_UTC,
            "package_type": PACKAGE_TYPE,
            "include_provisional": False,
        },
        "response_authority": {
            "git_blob": LEDGER_BLOB,
            "sha256": LEDGER_SHA256,
            "row_count": LEDGER_ROWS,
            "site_count": LEDGER_SITES,
            "sites_with_at_least_six_years": LEDGER_SITES_GE_6,
        },
        "schema_detail": expected_schema_detail(schema_rows),
        "inventory": {
            "file_inventory_rows": len(file_inventory_rows),
            "schema_inventory_rows": len(schema_rows),
            "f2_allowlist_rows": len(allowlist_rows),
            "metadata_files_fetched": len(REQUIRED_METADATA),
            "other_observation_files_excluded": excluded_count,
            "file_inventory_sha256": sha256_bytes(file_inventory_raw),
            "schema_inventory_sha256": sha256_bytes(schema_raw),
            "f2_allowlist_sha256": sha256_bytes(allowlist_raw),
        },
        "boundaries": {
            "observation_request_attempted": False,
            "observation_bytes_fetched": False,
            "ecological_value_accessed": False,
            "effect_path_called": False,
            "driver_artifact_changed": False,
            "f2_authorized": False,
        },
        "cleanup": {
            "cleanup_complete": True,
            "raw_files_remaining": 0,
            "capability_material_remaining": False,
        },
        "driver_hashes": dict(CANONICAL_DRIVER_HASHES),
    }


def validate_release_receipt(
    raw: bytes,
    *,
    file_inventory_raw: bytes,
    file_inventory_rows: list[dict[str, str]],
    schema_raw: bytes,
    schema_rows: list[dict[str, str]],
    allowlist_raw: bytes,
    allowlist_rows: list[dict[str, str]],
) -> None:
    receipt = strict_json(raw)
    _exact_mapping(receipt, {
        "schema_version", "gate", "source_sha", "f0_authority", "release",
        "request", "response_authority", "schema_detail", "inventory",
        "boundaries", "cleanup", "driver_hashes",
    })
    _exact_mapping(receipt.get("f0_authority"), {
        "merge", "tree", "spec_blob", "spec_sha256",
    })
    release = _exact_mapping(receipt.get("release"), {
        "tag", "uuid", "generation_utc", "doi", "package_type",
        "availability_manifest_name", "availability_manifest_byte_size",
        "availability_manifest_md5", "availability_manifest_sha256",
    })
    _exact_mapping(receipt.get("request"), {
        "product_code", "site_count", "site_roster_sha256", "start_month",
        "end_month", "start_utc", "end_utc", "package_type",
        "include_provisional",
    })
    _exact_mapping(receipt.get("response_authority"), {
        "git_blob", "sha256", "row_count", "site_count",
        "sites_with_at_least_six_years",
    })
    schema_detail = _exact_mapping(
        receipt.get("schema_detail"), set(SCHEMA_DETAIL_KINDS),
    )
    for family in SCHEMA_DETAIL_KINDS:
        _exact_mapping(schema_detail.get(family), {
            "record_kind", "metadata_sha256", "metadata_row_count",
            "detail_row_count", "detail_sha256",
        })
    _exact_mapping(receipt.get("inventory"), {
        "file_inventory_rows", "schema_inventory_rows", "f2_allowlist_rows",
        "metadata_files_fetched", "other_observation_files_excluded",
        "file_inventory_sha256", "schema_inventory_sha256",
        "f2_allowlist_sha256",
    })
    _exact_mapping(receipt.get("boundaries"), {
        "observation_request_attempted", "observation_bytes_fetched",
        "ecological_value_accessed", "effect_path_called",
        "driver_artifact_changed", "f2_authorized",
    })
    _exact_mapping(receipt.get("cleanup"), {
        "cleanup_complete", "raw_files_remaining",
        "capability_material_remaining",
    })
    _exact_mapping(receipt.get("driver_hashes"), set(CANONICAL_DRIVER_HASHES))

    source_sha = receipt.get("source_sha")
    availability_sha = release.get("availability_manifest_sha256")
    if not isinstance(source_sha, str) or HEX40.fullmatch(source_sha) is None:
        fail("receipt_schema_mismatch")
    if not isinstance(availability_sha, str) or HEX64.fullmatch(availability_sha) is None:
        fail("receipt_schema_mismatch")

    expected = expected_receipt(
        source_sha=source_sha,
        availability_sha256=availability_sha,
        file_inventory_raw=file_inventory_raw,
        file_inventory_rows=file_inventory_rows,
        schema_raw=schema_raw,
        schema_rows=schema_rows,
        allowlist_raw=allowlist_raw,
        allowlist_rows=allowlist_rows,
    )
    if receipt != expected or raw != canonical_json(expected):
        fail("receipt_contract_mismatch")


def _regular_file_bytes(path: Path, *, max_bytes: int | None = None) -> bytes:
    try:
        info = path.lstat()
    except OSError:
        fail("authority_file_unreadable")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        fail("authority_file_unreadable")
    if max_bytes is not None and info.st_size > max_bytes:
        fail("authority_file_unreadable")
    try:
        with path.open("rb") as handle:
            raw = handle.read()
    except OSError:
        fail("authority_file_unreadable")
    if len(raw) != info.st_size:
        fail("authority_file_unreadable")
    return raw


def _sha256_file(path: Path) -> str:
    try:
        info = path.lstat()
    except OSError:
        fail("authority_file_unreadable")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        fail("authority_file_unreadable")
    digest = hashlib.sha256()
    total = 0
    try:
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(READ_CHUNK), b""):
                total += len(chunk)
                digest.update(chunk)
    except OSError:
        fail("authority_file_unreadable")
    if total != info.st_size:
        fail("authority_file_unreadable")
    return digest.hexdigest()


def _find_repo_root_from_cwd() -> Path:
    cwd = Path.cwd().resolve()
    relative_paths = (SPEC_PATH, LEDGER_PATH, *CANONICAL_DRIVER_PATHS.values())
    for candidate in (cwd, *cwd.parents):
        present = [(candidate / relative).exists() for relative in relative_paths]
        if all(present):
            return candidate
        if any(present):
            fail("authority_surface_mismatch")
    fail("authority_surface_mismatch")


def _verify_ledger(raw: bytes) -> None:
    if sha256_bytes(raw) != LEDGER_SHA256 or git_blob_sha1(raw) != LEDGER_BLOB:
        fail("response_authority_mismatch")
    if not raw.endswith(b"\n") or b"\r" in raw or b"\x00" in raw:
        fail("response_authority_mismatch")
    try:
        lines = raw.decode("utf-8").splitlines()
    except UnicodeDecodeError:
        fail("response_authority_mismatch")
    if not lines or lines[0] != "siteID\tutc_calendar_year":
        fail("response_authority_mismatch")
    keys: list[tuple[str, int]] = []
    for line in lines[1:]:
        fields = line.split("\t")
        if (
            len(fields) != 2
            or fields[0] not in ROSTER_SET
            or YEAR.fullmatch(fields[1]) is None
        ):
            fail("response_authority_mismatch")
        keys.append((fields[0], int(fields[1])))
    if (
        len(keys) != LEDGER_ROWS
        or keys != sorted(keys)
        or len(keys) != len(set(keys))
        or {site for site, _year in keys} != ROSTER_SET
    ):
        fail("response_authority_mismatch")
    counts = {site: 0 for site in ROSTER}
    for site, _year in keys:
        counts[site] += 1
    if sum(count >= 6 for count in counts.values()) != LEDGER_SITES_GE_6:
        fail("response_authority_mismatch")


def verify_repo_authorities_if_present() -> None:
    root = _find_repo_root_from_cwd()
    spec = _regular_file_bytes(root / SPEC_PATH, max_bytes=8 * 1024 * 1024)
    if sha256_bytes(spec) != SPEC_SHA256 or git_blob_sha1(spec) != SPEC_BLOB:
        fail("spec_authority_mismatch")
    ledger = _regular_file_bytes(root / LEDGER_PATH, max_bytes=1024 * 1024)
    _verify_ledger(ledger)
    for label, relative in CANONICAL_DRIVER_PATHS.items():
        if _sha256_file(root / relative) != CANONICAL_DRIVER_HASHES[label]:
            fail("driver_artifact_changed")


def verify(directory: Path) -> None:
    outputs = _read_exact_receipt_family(directory)
    for raw in outputs.values():
        _assert_route_free(raw)

    file_inventory_raw = outputs[FILE_INVENTORY_NAME]
    schema_raw = outputs[SCHEMA_INVENTORY_NAME]
    allowlist_raw = outputs[ALLOWLIST_NAME]
    file_inventory_rows = parse_tsv(file_inventory_raw, FILE_INVENTORY_COLUMNS)
    schema_rows = parse_tsv(schema_raw, SCHEMA_COLUMNS)
    allowlist_rows = parse_tsv(allowlist_raw, ALLOWLIST_COLUMNS)

    validate_file_inventory(file_inventory_rows)
    validate_schema_inventory(schema_rows, file_inventory_rows)
    validate_allowlist(allowlist_rows, file_inventory_rows)
    validate_release_receipt(
        outputs[RECEIPT_NAME],
        file_inventory_raw=file_inventory_raw,
        file_inventory_rows=file_inventory_rows,
        schema_raw=schema_raw,
        schema_rows=schema_rows,
        allowlist_raw=allowlist_raw,
        allowlist_rows=allowlist_rows,
    )
    verify_repo_authorities_if_present()


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify one sanitized Continuous Discharge F1 receipt directory.",
    )
    parser.add_argument("sanitized_directory")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        verify(Path(args.sanitized_directory))
    except VerificationError as error:
        print(f"FAIL_CLOSED:{error.code}", file=sys.stderr)
        return 1
    except Exception:
        print("FAIL_CLOSED:unexpected_internal_error", file=sys.stderr)
        return 1
    print("PASS:discharge_f1_inventory_verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
