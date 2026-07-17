#!/usr/bin/env python3
"""Trusted, standard-library-only guard for the write-enabled publisher."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from urllib.parse import urlparse

DEPLOY_FILES = (
    "global.R",
    "ui.R",
    "server.R",
    "R/cascade_helpers.R",
    "R/site_metadata.R",
    "www/cascade.css",
    "www/cascade.js",
    "www/styles.css",
    "data/cascade.rds",
    "data/search_index.rds",
    "data/cascade_meta.rds",
    "data/neon-cascade-codebook.csv",
)
ARTIFACT_FILES = (
    "data/cascade.rds",
    "data/search_index.rds",
    "data/cascade_meta.rds",
    "data/neon-cascade-codebook.csv",
)
RECEIPT_NAME = "artifact-receipt.tsv"
RECEIPT_SCHEMA = "cascade-artifact-receipt-v1"
ROOT_FIELDS = {"version", "locale", "platform", "metadata", "packages", "files", "users"}
METADATA_FIELDS = {"appmode", "primary_rmd", "primary_html", "content_category", "has_parameters"}
ALLOWED_REPOSITORY_HOSTS = {
    "cloud.r-project.org",
    "cran.r-project.org",
    "cran.rstudio.com",
    "packagemanager.posit.co",
}
STANDARD_REMOTE_FIELDS = {
    "RemoteType", "RemoteRepos", "RemotePkgRef", "RemoteRef", "RemoteSha",
}
PROVENANCE_FIELD = re.compile(r"^(Remote|Github|GitLab|Bitbucket)", re.IGNORECASE)
FATAL_PACKAGES = {"neonutilities", "arrow"}
BASE_PACKAGES = {
    "r", "base", "compiler", "datasets", "graphics", "grdevices", "grid",
    "methods", "parallel", "splines", "stats", "stats4", "tcltk", "tools", "utils",
}
DIRECT_PACKAGES = {
    "shiny", "bslib", "bsicons", "dplyr", "plotly", "htmltools", "htmlwidgets",
    "shinyjs", "shinycssloaders", "DT", "tibble", "jsonlite",
}
PACKAGE_NAME = re.compile(r"^[A-Za-z][A-Za-z0-9.]*$")
PACKAGE_VERSION = re.compile(r"^[0-9]+(?:[.-][A-Za-z0-9]+)*$")
DEPENDENCY = re.compile(r"^([A-Za-z][A-Za-z0-9.]*)\s*(?:\([^()]+\))?$")
HEX32 = re.compile(r"^[0-9a-fA-F]{32}$")
HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
BUILT_R = re.compile(
    r"^R ([0-9]+)\.([0-9]+)\.[0-9]+; [^;\r\n]*; [^;\r\n]+; [^;\r\n]+$"
)


def fail(message: str) -> "NoReturn":
    raise SystemExit(message)


def exact_keys(value: object, expected: set[str], label: str) -> dict:
    if not isinstance(value, dict) or set(value) != expected:
        fail(f"{label} fields differ from the approved schema")
    return value


def trusted_repository(value: object) -> bool:
    if not isinstance(value, str) or not value or any(ord(char) < 33 or ord(char) == 127 for char in value):
        return False
    parsed = urlparse(value)
    return (
        parsed.scheme == "https"
        and parsed.hostname in ALLOWED_REPOSITORY_HOSTS
        and parsed.username is None
        and parsed.password is None
        and parsed.port is None
        and not parsed.query
        and not parsed.fragment
    )


def reject_duplicate_json_keys(pairs: list[tuple[str, object]]) -> dict:
    value: dict[str, object] = {}
    for key, item in pairs:
        if key in value:
            fail(f"manifest JSON contains a duplicate key: {key}")
        value[key] = item
    return value


def read_json(path: Path) -> dict:
    if path.is_symlink() or not path.is_file():
        fail(f"manifest is not a regular file: {path}")
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=reject_duplicate_json_keys,
            parse_constant=lambda constant: fail(f"manifest JSON constant is forbidden: {constant}"),
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        fail(f"cannot parse {path}: {error}")
    if not isinstance(value, dict):
        fail("manifest root must be a JSON object")
    return value


def file_digest(path: Path, algorithm: str) -> str:
    digest = hashlib.new(algorithm)
    try:
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError as error:
        fail(f"cannot hash {path}: {error}")
    return digest.hexdigest()


def assert_regular_deploy_files(root: Path) -> None:
    for relative in DEPLOY_FILES:
        path = root / relative
        if path.is_symlink() or not path.is_file():
            fail(f"deploy entry is not a regular, non-symbolic-link file: {relative}")


def assert_canonical_deploy_text(root: Path) -> None:
    for relative in DEPLOY_FILES:
        if not relative.lower().endswith((".r", ".css", ".js", ".csv")):
            continue
        path = root / relative
        if path.is_symlink() or not path.is_file():
            fail(f"deploy entry is not a regular file: {relative}")
        data = path.read_bytes()
        if b"\x00" in data or b"\r" in data:
            fail(f"deploy text is not NUL-free canonical LF: {relative}")
        try:
            data.decode("utf-8")
        except UnicodeDecodeError as error:
            fail(f"deploy text is not UTF-8: {relative}: {error}")


def mandatory_dependencies(package: str, description: dict) -> set[str]:
    dependencies: set[str] = set()
    for field in ("Depends", "Imports", "LinkingTo"):
        value = description.get(field)
        if value is None:
            continue
        if not isinstance(value, str) or not value:
            fail(f"manifest dependency metadata is malformed: {package}")
        for entry in value.split(","):
            entry = entry.strip()
            if not entry:
                continue
            match = DEPENDENCY.fullmatch(entry)
            if match is None:
                fail(f"manifest dependency metadata is malformed: {package}")
            dependency = match.group(1)
            if dependency.lower() not in BASE_PACKAGES:
                dependencies.add(dependency)
    return dependencies


def resolve_manifest_path(path: Path, root: Path) -> Path:
    root = root.resolve(strict=True)
    try:
        resolved = path.resolve(strict=True)
    except OSError as error:
        fail(f"cannot resolve manifest path: {error}")
    if resolved != root / "manifest.json":
        fail("manifest path must be the trusted checkout root manifest.json")
    return resolved


def validate_manifest(manifest: dict, root: Path, check_checksums: bool) -> None:
    exact_keys(manifest, ROOT_FIELDS, "manifest root")
    if type(manifest["version"]) is not int or manifest["version"] != 1:
        fail("manifest version must be 1")
    if manifest["locale"] != "en_US" or manifest["platform"] != "4.5.2":
        fail("manifest locale or R platform is not approved")
    if manifest["users"] is not None:
        fail("manifest users must be null")

    metadata = exact_keys(manifest["metadata"], METADATA_FIELDS, "manifest metadata")
    if metadata != {
        "appmode": "shiny",
        "primary_rmd": None,
        "primary_html": None,
        "content_category": None,
        "has_parameters": False,
    }:
        fail("manifest metadata must describe a parameter-free Shiny app")

    entries = manifest["files"]
    if not isinstance(entries, dict) or set(entries) != set(DEPLOY_FILES):
        fail("manifest deploy surface differs from the exact allowlist")
    for relative in DEPLOY_FILES:
        entry = exact_keys(entries[relative], {"checksum"}, f"manifest file {relative}")
        checksum = entry["checksum"]
        if not isinstance(checksum, str) or not HEX32.fullmatch(checksum):
            fail(f"manifest checksum is malformed: {relative}")

    packages = manifest["packages"]
    if not isinstance(packages, dict) or not packages:
        fail("manifest package map must be nonempty")
    lowered = [name.lower() for name in packages]
    if len(lowered) != len(set(lowered)) or any(not PACKAGE_NAME.fullmatch(name) for name in packages):
        fail("manifest package names are invalid or case-insensitively duplicated")
    leaked = sorted(name for name in packages if name.lower() in FATAL_PACKAGES)
    if leaked:
        fail(f"forbidden deploy package(s): {', '.join(leaked)}")

    dependency_map: dict[str, set[str]] = {}
    for name, record_value in packages.items():
        record = exact_keys(record_value, {"Source", "Repository", "description"}, f"package {name}")
        description = record["description"]
        if not isinstance(description, dict):
            fail(f"package description is malformed: {name}")
        required = {"Package", "Version", "Repository", "Built"}
        if not required.issubset(description):
            fail(f"package description is incomplete: {name}")
        version = description["Version"]
        built = description["Built"]
        built_match = BUILT_R.match(built) if isinstance(built, str) else None
        if (
            record["Source"] != "CRAN"
            or not trusted_repository(record["Repository"])
            or description["Package"] != name
            or not isinstance(version, str)
            or not PACKAGE_VERSION.fullmatch(version)
            or description["Repository"] != "CRAN"
            or built_match is None
            or built_match.groups() != ("4", "5")
        ):
            fail(f"package record is incomplete, untrusted, or R-incompatible: {name}")

        present = {field for field in STANDARD_REMOTE_FIELDS if field in description}
        provenance_names = {field for field in description if PROVENANCE_FIELD.match(field)}
        unexpected = sorted(provenance_names - STANDARD_REMOTE_FIELDS)
        if unexpected:
            fail(f"unexpected package provenance field(s) for {name}: {', '.join(unexpected)}")
        if present and present != STANDARD_REMOTE_FIELDS:
            fail(f"partial standard CRAN provenance: {name}")
        if present and (
            description["RemoteType"] != "standard"
            or description["RemotePkgRef"] != name
            or description["RemoteRef"] != name
            or description["RemoteSha"] != version
            or not trusted_repository(description["RemoteRepos"])
        ):
            fail(f"explicit standard CRAN provenance is invalid: {name}")
        dependency_map[name] = mandatory_dependencies(name, description)

    package_by_lower = {name.lower(): name for name in packages}
    missing_dependencies = sorted({
        dependency
        for dependencies in dependency_map.values()
        for dependency in dependencies
        if dependency.lower() not in package_by_lower
    })
    if missing_dependencies:
        fail(f"mandatory recursive package dependency record(s) missing: {', '.join(missing_dependencies)}")
    missing_direct = sorted(name for name in DIRECT_PACKAGES if name.lower() not in package_by_lower)
    if missing_direct:
        fail(f"direct runtime package record(s) missing: {', '.join(missing_direct)}")
    reachable: set[str] = set()
    queue = [package_by_lower[name.lower()] for name in DIRECT_PACKAGES]
    while queue:
        name = queue.pop()
        if name in reachable:
            continue
        reachable.add(name)
        queue.extend(package_by_lower[dependency.lower()] for dependency in dependency_map[name])
    unreachable = sorted(set(packages) - reachable)
    if unreachable:
        fail(f"manifest package graph contains unreachable record(s): {', '.join(unreachable)}")

    if "data.table" in lowered:
        plotly_name = next((name for name in packages if name.lower() == "plotly"), None)
        imports = "" if plotly_name is None else packages[plotly_name]["description"].get("Imports", "")
        if not isinstance(imports, str) or not re.search(r"(?:^|[,\s])data\.table(?:\s*\([^)]*\))?(?=[,\s]|$)", imports):
            fail("data.table may appear only as plotly's declared transitive dependency")

    assert_regular_deploy_files(root)
    assert_canonical_deploy_text(root)
    if check_checksums:
        for relative in DEPLOY_FILES:
            actual = file_digest(root / relative, "md5")
            if entries[relative]["checksum"].lower() != actual:
                fail(f"manifest checksum mismatch: {relative}")


def update_manifest(path: Path, root: Path) -> None:
    path = resolve_manifest_path(path, root)
    manifest = read_json(path)
    validate_manifest(manifest, root, check_checksums=False)
    package_fingerprint = json.dumps(manifest["packages"], ensure_ascii=False, sort_keys=True)
    for relative in DEPLOY_FILES:
        manifest["files"][relative]["checksum"] = file_digest(root / relative, "md5")
    if package_fingerprint != json.dumps(manifest["packages"], ensure_ascii=False, sort_keys=True):
        fail("manifest package graph changed during checksum refresh")
    rendered = json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", newline="\n", dir=path.parent,
                                     prefix=".manifest-", suffix=".tmp", delete=False) as handle:
        handle.write(rendered)
        temporary = Path(handle.name)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)
    validate_manifest(read_json(path), root, check_checksums=True)


def verify_receipt(base_sha: str, root: Path) -> None:
    if not HEX40.fullmatch(base_sha):
        fail("expected workflow base SHA is malformed")
    root = root.resolve(strict=True)
    receipt = root / RECEIPT_NAME
    expected_entries = {"data", RECEIPT_NAME, *ARTIFACT_FILES}
    actual_entries: set[str] = set()
    for path in root.rglob("*"):
        relative = path.relative_to(root).as_posix()
        actual_entries.add(relative)
        if path.is_symlink():
            fail(f"artifact surface contains a symbolic link: {relative}")
    if actual_entries != expected_entries:
        fail(
            "artifact surface mismatch "
            f"(missing: {sorted(expected_entries - actual_entries)}; "
            f"unexpected: {sorted(actual_entries - expected_entries)})"
        )
    for relative in ARTIFACT_FILES:
        if not (root / relative).is_file():
            fail(f"artifact is not a regular file: {relative}")
    data = receipt.read_bytes()
    if b"\x00" in data or b"\r" in data:
        fail("artifact receipt is not NUL-free canonical LF")
    try:
        lines = data.decode("utf-8").splitlines()
    except UnicodeDecodeError as error:
        fail(f"artifact receipt is not UTF-8: {error}")
    if len(lines) != 2 + len(ARTIFACT_FILES) or lines[0] != RECEIPT_SCHEMA:
        fail("artifact receipt schema or row count is invalid")
    if lines[1] != f"base\t{base_sha}":
        fail("artifact receipt base does not match the immutable workflow SHA")
    for line, relative in zip(lines[2:], ARTIFACT_FILES, strict=True):
        fields = line.split("\t")
        if len(fields) != 3 or fields[0] != "sha256" or fields[2] != relative:
            fail(f"artifact receipt row is malformed: {relative}")
        if not HEX64.fullmatch(fields[1]):
            fail(f"artifact receipt SHA-256 is malformed: {relative}")
        actual = file_digest(root / relative, "sha256")
        if fields[1] != actual:
            fail(f"artifact receipt SHA-256 mismatch: {relative}")


def main(argv: list[str]) -> None:
    if len(argv) == 4 and argv[1] == "verify-receipt":
        verify_receipt(argv[2], Path(argv[3]))
    elif len(argv) == 3 and argv[1] == "update-manifest":
        path = Path(argv[2])
        update_manifest(path, Path.cwd())
    elif len(argv) == 3 and argv[1] == "verify-manifest":
        path = resolve_manifest_path(Path(argv[2]), Path.cwd())
        validate_manifest(read_json(path), Path.cwd(), check_checksums=True)
    else:
        fail("usage: trusted_publish.py <verify-receipt BASE ROOT|update-manifest PATH|verify-manifest PATH>")


if __name__ == "__main__":
    main(sys.argv)
