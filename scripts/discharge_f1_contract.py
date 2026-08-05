#!/usr/bin/env python3
"""Pure, values-free contract for the Continuous Discharge F1 inventory.

This module has no network or subprocess capability.  It validates immutable
release metadata, classifies manifest filenames before a caller may inspect a
download route, parses only preregistered non-observation metadata, and emits
canonical route-free receipt bytes.  Observation-table bytes are an F2 concern
and are never accepted by this module.
"""

from __future__ import annotations

from dataclasses import dataclass
import csv
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path
import re
from typing import Iterable, Mapping, NoReturn, Sequence
from urllib.parse import unquote, urlsplit


CONTRACT_VERSION = "discharge-feasibility-f1-v1"
F0_AUTHORITY_MERGE = "b75996a85809ed0cd8ba89121e0de18e22063cc7"
F0_AUTHORITY_TREE = "8e7b774da4fc8486fb3c41e790317c61d5af9379"
SPEC_BLOB = "643dbaa3489bb8100de691b2de0ead124f842502"
SPEC_SHA256 = "831baf97f6558a7d0bccacb401880929ffccd7a6ebf210b8ee70d536db298ac7"

PRODUCT_CODE = "DP4.00130.001"
PRODUCT_NAME = "Continuous discharge"
PACKAGE_TYPE = "expanded"
RELEASE_TAG = "RELEASE-2026"
RELEASE_UUID = "c28725ff-5aa2-41fa-845e-a7f1c8239d09"
RELEASE_GENERATION_UTC = "2026-01-23T00:07:49Z"
PRODUCT_DOI = "10.48443/4n6c-gc44"
AVAILABILITY_NAME = "manifest-available-20260123T000738Z.json"
AVAILABILITY_BYTES = 2_779_477
AVAILABILITY_MD5 = "33c04c0f24dba030d3082acf704e2c56"
INCLUDE_PROVISIONAL = False
REQUEST_START_MONTH = "2016-08"
LAST_ALLOWED_MONTH = "2024-09"
REQUEST_START_UTC = "2016-08-01T00:00:00Z"
REQUEST_END_UTC = "2024-09-30T23:59:59Z"

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
EXCLUDED_SITES = frozenset({"TOMB", "TOOK"})

MAIN_TABLES = ("csd_15_min", "csd_continuousDischarge")
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
OTHER_OBSERVATION = re.compile(r"^(?:csd|sdrc|geo|bat)_[A-Za-z0-9_]+$")

REQUIRED_METADATA = (
    "variables_00130",
    "validation_00130",
    "categoricalCodes_00130",
    "readme_00130",
    "issueLog_00130",
)
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

CANONICAL_DRIVER_HASHES = {
    "cascade": "47b98e48ebf3891c151588c87691fee63760bdf8b66196dc4e7ffa3d0ae1f3fe",
    "search": "a11a072d331afc72fe04aeedfe200bfab28a3122f59dfd556ee78901c0374f0e",
    "meta": "00120c52a156fffe49146d952cfc3b871805ce8911869374e51fa2ac5b8d14de",
    "codebook": "a79cc754a0d984e8593fdbf84ccde518a6a6416a7bfbbc86d87e9de49a4138c3",
    "manifest": "92b46277d4aa9cee08941855a3693296298c14c74c774d7b5452f93a63441e79",
}
CANONICAL_DRIVER_PATHS = {
    "cascade": "data/cascade.rds",
    "search": "data/search_index.rds",
    "meta": "data/cascade_meta.rds",
    "codebook": "data/neon-cascade-codebook.csv",
    "manifest": "manifest.json",
}

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
DOMAIN = re.compile(r"^D[0-9]{2}$")
COMPACT_UTC = re.compile(r"^20[0-9]{6}T[0-9]{6}Z$")
CALENDAR_DATE = re.compile(r"^20[0-9]{2}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])$")
BASENAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,254}$")
SAFE_URL_HOSTS = frozenset({"data.neonscience.org", "storage.googleapis.com"})


class F1Error(RuntimeError):
    """A bounded failure reason safe to expose in CI logs."""

    def __init__(self, code: str):
        if not re.fullmatch(r"[a-z0-9_]+", code):
            code = "unexpected_internal_error"
        super().__init__(code)
        self.code = code


def fail(code: str) -> NoReturn:
    raise F1Error(code)


def exact_keys(value: object, expected: set[str], code: str) -> dict:
    if not isinstance(value, dict) or set(value) != expected:
        fail(code)
    return value


def reject_duplicate_json_keys(pairs: list[tuple[str, object]]) -> dict:
    output: dict[str, object] = {}
    for key, value in pairs:
        if key in output:
            fail("duplicate_json_key")
        output[key] = value
    return output


def strict_json_loads(raw: bytes, *, max_bytes: int) -> dict:
    if not isinstance(raw, bytes) or not raw or len(raw) > max_bytes:
        fail("malformed_or_oversized_json")
    try:
        text = raw.decode("utf-8")
        value = json.loads(
            text,
            object_pairs_hook=reject_duplicate_json_keys,
            parse_constant=lambda _: fail("forbidden_json_constant"),
        )
    except (UnicodeDecodeError, json.JSONDecodeError):
        fail("malformed_json")
    if not isinstance(value, dict):
        fail("malformed_json")
    return value


def sha256_bytes(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def md5_bytes(raw: bytes) -> str:
    return hashlib.md5(raw, usedforsecurity=False).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    try:
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError:
        fail("authority_file_unreadable")
    return digest.hexdigest()


def normalize_utc(value: object) -> str:
    if not isinstance(value, str):
        fail("release_identity_mismatch")
    match = re.fullmatch(
        r"([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(?:[.]0+)?Z",
        value,
    )
    if match is None:
        fail("release_identity_mismatch")
    try:
        parsed = datetime.strptime(
            match.group(1) + "Z", "%Y-%m-%dT%H:%M:%SZ",
        ).replace(tzinfo=timezone.utc)
    except ValueError:
        fail("release_identity_mismatch")
    return parsed.strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_compact_utc(value: object) -> str:
    if not isinstance(value, str) or COMPACT_UTC.fullmatch(value) is None:
        fail("manifest_allowlist_mismatch")
    try:
        parsed = datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(
            tzinfo=timezone.utc,
        )
    except ValueError:
        fail("manifest_allowlist_mismatch")
    return parsed.strftime("%Y-%m-%dT%H:%M:%SZ")


def validate_calendar_date(value: str) -> str:
    if not value:
        return value
    if CALENDAR_DATE.fullmatch(value) is None:
        fail("unexpected_qc_token")
    try:
        datetime.strptime(value, "%Y-%m-%d")
    except ValueError:
        fail("unexpected_qc_token")
    return value


def normalize_doi(value: object) -> str:
    if not isinstance(value, str):
        fail("release_identity_mismatch")
    prefixes = ("https://doi.org/", "http://doi.org/", "doi:")
    normalized = value.strip()
    for prefix in prefixes:
        if normalized.lower().startswith(prefix):
            normalized = normalized[len(prefix):]
            break
    if normalized != PRODUCT_DOI:
        fail("release_identity_mismatch")
    return normalized


def validated_route(value: object) -> str:
    """Validate a capability route without returning any printable derivative."""
    if not isinstance(value, str) or not value or len(value) > 4096:
        fail("manifest_allowlist_mismatch")
    if any(ord(char) < 33 or ord(char) == 127 for char in value):
        fail("credential_or_capability_exposed")
    parsed = urlsplit(value)
    if (
        parsed.scheme != "https"
        or parsed.hostname not in SAFE_URL_HOSTS
        or parsed.username is not None
        or parsed.password is not None
        or parsed.port is not None
        or parsed.fragment
        or not parsed.path.startswith("/")
        or unquote(parsed.path) != parsed.path
    ):
        fail("manifest_allowlist_mismatch")
    return value


def validate_basename(name: object) -> tuple[str, tuple[str, ...]]:
    if not isinstance(name, str) or BASENAME.fullmatch(name) is None:
        fail("manifest_allowlist_mismatch")
    if (
        name in {".", ".."}
        or ".." in name
        or any(char in name for char in "/\\%?#:@")
        or any(char.isspace() for char in name)
    ):
        fail("manifest_allowlist_mismatch")
    try:
        name.encode("ascii")
    except UnicodeEncodeError:
        fail("manifest_allowlist_mismatch")
    tokens = tuple(name.split("."))
    if any(not token for token in tokens):
        fail("manifest_allowlist_mismatch")
    dpid = ("DP4", "00130", "001")
    matches = sum(tokens[index:index + 3] == dpid for index in range(len(tokens) - 2))
    if matches != 1:
        fail("manifest_allowlist_mismatch")
    return name, tokens


@dataclass(frozen=True)
class FileRecord:
    release: str
    package_type: str
    domain_code: str
    package_generation_utc: str
    site_id: str
    year_month: str
    file_role: str
    logical_family: str
    file_name: str
    file_generation_utc: str
    byte_size: int
    md5: str
    crc32c: str
    route: str | None = None

    def inventory_row(self) -> dict[str, object]:
        return {
            "release": self.release,
            "package_type": self.package_type,
            "domain_code": self.domain_code,
            "package_generation_utc": self.package_generation_utc,
            "site_id": self.site_id,
            "year_month": self.year_month,
            "file_role": self.file_role,
            "logical_family": self.logical_family,
            "file_name": self.file_name,
            "file_generation_utc": self.file_generation_utc,
            "byte_size": self.byte_size,
            "md5": self.md5,
            "crc32c": self.crc32c,
        }

    def allowlist_row(self) -> dict[str, object]:
        if self.file_role != "f2_identity_only" or self.logical_family not in MAIN_TABLES:
            fail("manifest_allowlist_mismatch")
        return {
            "release": self.release,
            "package_type": self.package_type,
            "domain_code": self.domain_code,
            "package_generation_utc": self.package_generation_utc,
            "site_id": self.site_id,
            "year_month": self.year_month,
            "table_family": self.logical_family,
            "file_name": self.file_name,
            "file_generation_utc": self.file_generation_utc,
            "byte_size": self.byte_size,
            "md5": self.md5,
            "crc32c": self.crc32c,
        }


@dataclass(frozen=True)
class ReleaseAuthority:
    availability_route: str


def _reject_family_near_match(family: str) -> None:
    for exact in ALL_METADATA + MAIN_TABLES + (SPECIAL_TABLE,):
        if family != exact and (
            family.lower() == exact.lower()
            or family.startswith(exact + "_")
            or family.startswith(exact + "-")
        ):
            fail("manifest_allowlist_mismatch")


def classify_filename(
    name: object,
    *,
    domain_code: str,
    site_id: str,
    year_month: str,
    package_generation_utc: str,
) -> tuple[str, str, str]:
    """Classify one exact NEON basename before its route may be accessed."""
    _file_name, tokens = validate_basename(name)
    if DOMAIN.fullmatch(domain_code) is None or site_id not in ROSTER:
        fail("manifest_allowlist_mismatch")
    if MONTH.fullmatch(year_month) is None:
        fail("manifest_allowlist_mismatch")
    if year_month < REQUEST_START_MONTH:
        fail("manifest_allowlist_mismatch")
    if year_month > LAST_ALLOWED_MONTH:
        fail("provisional_input_present")
    package_generation = normalize_utc(package_generation_utc)
    if (
        package_generation > RELEASE_GENERATION_UTC
        or package_generation[:7] < year_month
    ):
        fail("release_identity_mismatch")

    # Shared product metadata has no domain, site, month, or package tokens.  The
    # only accepted variants are the canonical basename with no generation token
    # and the same basename with one well-formed release-era generation token.
    if len(tokens) in {6, 7} and tokens[:4] == ("NEON", "DP4", "00130", "001"):
        family = tokens[4]
        _reject_family_near_match(family)
        if family in ALL_METADATA:
            extension = tokens[-1]
            allowed_extensions = {"csv"}
            if family in {"readme_00130", "citation_00130_RELEASE-2026"}:
                allowed_extensions = {"csv", "txt"}
            if extension not in allowed_extensions:
                fail("manifest_allowlist_mismatch")
            file_generation = ""
            if len(tokens) == 7:
                file_generation = normalize_compact_utc(tokens[5])
                if file_generation > RELEASE_GENERATION_UTC:
                    fail("release_identity_mismatch")
            role = (
                "metadata_bytes_allowed"
                if family in REQUIRED_METADATA
                else "metadata_identity_only"
            )
            return role, family, file_generation

    # Observation identities are exact package basenames.  Positional equality
    # makes a second site/month/domain/package token impossible by construction.
    if len(tokens) != 11:
        fail("manifest_allowlist_mismatch")
    (
        neon, file_domain, file_site, dp_level, product, revision, family,
        file_month, file_package, compact_generation, extension,
    ) = tokens
    _reject_family_near_match(family)
    if (
        neon != "NEON"
        or file_domain != domain_code
        or file_site != site_id
        or (dp_level, product, revision) != ("DP4", "00130", "001")
        or file_month != year_month
        or file_package != PACKAGE_TYPE
        or extension != "csv"
        or any(token in EXCLUDED_SITES for token in tokens)
    ):
        fail("manifest_allowlist_mismatch")
    file_generation = normalize_compact_utc(compact_generation)
    if file_generation > package_generation or file_generation[:7] < year_month:
        fail("release_identity_mismatch")
    if family in MAIN_TABLES:
        return "f2_identity_only", family, file_generation
    if family == SPECIAL_TABLE:
        return "known_special_excluded", family, file_generation
    if family in KNOWN_OTHER_TABLES or OTHER_OBSERVATION.fullmatch(family):
        return "other_observation_excluded", family, file_generation
    fail("manifest_allowlist_mismatch")


def _validated_file_scalar(value: object, pattern: re.Pattern[str], code: str) -> str:
    if not isinstance(value, str) or pattern.fullmatch(value) is None:
        fail(code)
    return value


def validate_release_payload(payload: dict) -> ReleaseAuthority:
    root = exact_keys(payload, {"data"}, "release_identity_mismatch")
    data = root["data"]
    if not isinstance(data, dict):
        fail("release_identity_mismatch")
    required = {"release", "uuid", "generationDate", "artifacts", "dataProducts"}
    if not required.issubset(data):
        fail("release_identity_mismatch")
    if (
        data["release"] != RELEASE_TAG
        or data["uuid"] != RELEASE_UUID
        or normalize_utc(data["generationDate"]) != RELEASE_GENERATION_UTC
    ):
        fail("release_identity_mismatch")

    products = data["dataProducts"]
    if not isinstance(products, list):
        fail("release_identity_mismatch")
    matches = [item for item in products if isinstance(item, dict) and item.get("productCode") == PRODUCT_CODE]
    if len(matches) != 1:
        fail("release_identity_mismatch")
    product = matches[0]
    if product.get("productName") != PRODUCT_NAME:
        fail("release_identity_mismatch")
    normalize_doi(product.get("productDoi"))

    artifacts = data["artifacts"]
    if not isinstance(artifacts, list):
        fail("release_identity_mismatch")
    matches = [item for item in artifacts if isinstance(item, dict) and item.get("name") == AVAILABILITY_NAME]
    if len(matches) != 1:
        fail("release_identity_mismatch")
    artifact = matches[0]
    if (
        type(artifact.get("size")) is not int
        or artifact.get("size") != AVAILABILITY_BYTES
        or artifact.get("md5") != AVAILABILITY_MD5
    ):
        fail("release_identity_mismatch")
    # Access the route only after exact artifact classification and identity checks.
    return ReleaseAuthority(availability_route=validated_route(artifact.get("url")))


def validate_availability_bytes(raw: bytes) -> str:
    if len(raw) != AVAILABILITY_BYTES or md5_bytes(raw) != AVAILABILITY_MD5:
        fail("release_identity_mismatch")
    strict_json_loads(raw, max_bytes=AVAILABILITY_BYTES)
    return sha256_bytes(raw)


def validate_query_payload(payload: dict) -> list[FileRecord]:
    root = exact_keys(payload, {"data"}, "manifest_allowlist_mismatch")
    data = exact_keys(
        root["data"],
        {"productCode", "siteCodes", "startDate", "endDate", "packageType", "releases"},
        "manifest_allowlist_mismatch",
    )
    if data["productCode"] != PRODUCT_CODE or data["packageType"] != PACKAGE_TYPE:
        fail("package_not_expanded")
    if (
        normalize_utc(data["startDate"]) != REQUEST_START_UTC
        or normalize_utc(data["endDate"]) != REQUEST_END_UTC
    ):
        fail("release_identity_mismatch")
    site_codes = data["siteCodes"]
    if (
        not isinstance(site_codes, list)
        or any(not isinstance(site, str) for site in site_codes)
        or tuple(sorted(site_codes)) != ROSTER
    ):
        fail("response_210_24_23_mismatch")
    releases = data["releases"]
    if not isinstance(releases, list) or len(releases) != 1:
        fail("release_identity_mismatch")
    release = exact_keys(
        releases[0], {"release", "generationDate", "packages"},
        "release_identity_mismatch",
    )
    if release["release"] != RELEASE_TAG or normalize_utc(release["generationDate"]) != RELEASE_GENERATION_UTC:
        fail("release_identity_mismatch")
    packages = release["packages"]
    if not isinstance(packages, list):
        fail("manifest_allowlist_mismatch")

    records: list[FileRecord] = []
    package_keys: set[tuple[str, str]] = set()
    file_keys: set[tuple[str, str, str]] = set()
    for package in packages:
        package = exact_keys(
            package,
            {"domainCode", "siteCode", "month", "packageType", "generationDate", "files"},
            "manifest_allowlist_mismatch",
        )
        domain = package["domainCode"]
        site = package["siteCode"]
        month = package["month"]
        if not isinstance(domain, str) or DOMAIN.fullmatch(domain) is None:
            fail("manifest_allowlist_mismatch")
        if site not in ROSTER or site in EXCLUDED_SITES:
            fail("manifest_allowlist_mismatch")
        if not isinstance(month, str) or MONTH.fullmatch(month) is None:
            fail("manifest_allowlist_mismatch")
        if month < REQUEST_START_MONTH:
            fail("manifest_allowlist_mismatch")
        if month > LAST_ALLOWED_MONTH:
            fail("provisional_input_present")
        if package["packageType"] != PACKAGE_TYPE:
            fail("package_not_expanded")
        package_generation = normalize_utc(package["generationDate"])
        if (
            package_generation > RELEASE_GENERATION_UTC
            or package_generation[:7] < month
        ):
            fail("release_identity_mismatch")
        package_key = (site, month)
        if package_key in package_keys:
            fail("duplicate_source_key")
        package_keys.add(package_key)
        files = package["files"]
        if not isinstance(files, list):
            fail("manifest_allowlist_mismatch")
        for file_item in files:
            file_item = exact_keys(
                file_item, {"name", "size", "md5", "crc32c", "url"},
                "manifest_allowlist_mismatch",
            )
            name = file_item["name"]
            # Filename classification deliberately precedes access to the URL field.
            role, family, file_generation = classify_filename(
                name,
                domain_code=domain,
                site_id=site,
                year_month=month,
                package_generation_utc=package_generation,
            )
            size = file_item["size"]
            if type(size) is not int or size < 0:
                fail("manifest_allowlist_mismatch")
            md5 = _validated_file_scalar(file_item["md5"], HEX32, "manifest_allowlist_mismatch")
            crc32c = _validated_file_scalar(file_item["crc32c"], CRC32C, "manifest_allowlist_mismatch")
            key = (site, month, name)
            if key in file_keys:
                fail("duplicate_source_key")
            file_keys.add(key)
            route = None
            if role == "metadata_bytes_allowed":
                route = validated_route(file_item["url"])
            records.append(FileRecord(
                release=RELEASE_TAG,
                package_type=PACKAGE_TYPE,
                domain_code=domain,
                package_generation_utc=package_generation,
                site_id=site,
                year_month=month,
                file_role=role,
                logical_family=family,
                file_name=name,
                file_generation_utc=file_generation,
                byte_size=size,
                md5=md5,
                crc32c=crc32c,
                route=route,
            ))

    for family in REQUIRED_METADATA:
        if not any(record.logical_family == family for record in records):
            fail("required_table_missing")
    for table in MAIN_TABLES:
        if not any(record.logical_family == table for record in records):
            fail("required_table_missing")
    return sorted(
        records,
        key=lambda record: (
            record.site_id, record.year_month, record.domain_code,
            record.package_generation_utc, record.file_role,
            record.logical_family, record.file_name,
            record.file_generation_utc, record.md5, record.crc32c,
        ),
    )


def unique_metadata_downloads(records: Sequence[FileRecord]) -> list[FileRecord]:
    by_family: dict[str, dict[tuple[object, ...], FileRecord]] = {
        family: {} for family in REQUIRED_METADATA
    }
    name_identity: dict[tuple[str, str], tuple[object, ...]] = {}
    for record in records:
        if record.file_role != "metadata_bytes_allowed":
            continue
        identity = (
            record.file_name, record.byte_size, record.md5, record.crc32c,
        )
        name_key = (record.logical_family, record.file_name)
        prior = name_identity.get(name_key)
        if prior is not None and prior != identity:
            fail("duplicate_source_key")
        name_identity[name_key] = identity
        by_family[record.logical_family].setdefault(identity, record)
    output: list[FileRecord] = []
    for family in REQUIRED_METADATA:
        identities = by_family[family]
        if len(identities) != 1:
            fail("manifest_allowlist_mismatch")
        record = next(iter(identities.values()))
        if record.route is None:
            fail("manifest_allowlist_mismatch")
        output.append(record)
    return output


def _decode_csv(raw: bytes, family: str) -> tuple[tuple[str, ...], list[dict[str, str]]]:
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        fail("unexpected_field_class")
    if "\x00" in text:
        fail("unexpected_field_class")
    reader = csv.reader(io.StringIO(text, newline=""))
    try:
        rows = list(reader)
    except csv.Error:
        fail("unexpected_field_class")
    if not rows:
        fail("required_table_missing")
    header = tuple(rows[0])
    expected = METADATA_HEADERS[family]
    if header != expected or len(set(header)) != len(header):
        fail("unexpected_field_class")
    output: list[dict[str, str]] = []
    for row in rows[1:]:
        if len(row) != len(header):
            fail("unexpected_field_class")
        output.append(dict(zip(header, row)))
    return header, output


def _columns_digest(header: Sequence[str]) -> str:
    if not header:
        return sha256_bytes(b"")
    return sha256_bytes(("\t".join(header) + "\n").encode("utf-8"))


def _schema_row(**values: object) -> dict[str, object]:
    if not set(values).issubset(SCHEMA_COLUMNS):
        fail("receipt_schema_mismatch")
    row: dict[str, object] = {column: "" for column in SCHEMA_COLUMNS}
    row.update(values)
    return row


def inspect_metadata(
    payloads: Mapping[str, tuple[FileRecord, bytes]],
) -> list[dict[str, object]]:
    if set(payloads) != set(REQUIRED_METADATA):
        fail("required_table_missing")
    parsed: dict[str, list[dict[str, str]]] = {}
    schema_rows: list[dict[str, object]] = []
    for family in REQUIRED_METADATA:
        record, raw = payloads[family]
        if record.logical_family != family or record.file_role != "metadata_bytes_allowed":
            fail("manifest_allowlist_mismatch")
        if len(raw) != record.byte_size or md5_bytes(raw) != record.md5:
            fail("manifest_allowlist_mismatch")
        metadata_sha = sha256_bytes(raw)
        if family == "readme_00130":
            try:
                text = raw.decode("utf-8-sig")
            except UnicodeDecodeError:
                fail("unexpected_field_class")
            if not text.strip() or "\x00" in text:
                fail("required_table_missing")
            header: tuple[str, ...] = ()
            rows: list[dict[str, str]] = []
        else:
            header, rows = _decode_csv(raw, family)
        parsed[family] = rows
        schema_rows.append(_schema_row(
            record_kind="metadata_file",
            metadata_family=family,
            file_name=record.file_name,
            metadata_sha256=metadata_sha,
            metadata_row_count=len(rows),
            metadata_columns_sha256=_columns_digest(header),
        ))

    variables = parsed["variables_00130"]
    identities: set[tuple[str, str]] = set()
    categorical_rows_by_name: dict[str, list[dict[str, str]]] = {}
    categorical_identities: set[tuple[str, str, str, str]] = set()
    for row in parsed["categoricalCodes_00130"]:
        name = row["name"]
        pub_code = row["pubCode"]
        start_date = validate_calendar_date(row["startDate"])
        end_date = validate_calendar_date(row["endDate"])
        if not name or not pub_code or (start_date and end_date and start_date > end_date):
            fail("unexpected_qc_token")
        identity = (name, pub_code, start_date, end_date)
        if identity in categorical_identities:
            fail("duplicate_source_key")
        categorical_identities.add(identity)
        categorical_rows_by_name.setdefault(name, []).append(row)

    declaration_rows: list[dict[str, object]] = []
    for row in variables:
        table = row["table"]
        field = row["fieldName"]
        if not table or not field or (table, field) in identities:
            fail("duplicate_source_key")
        identities.add((table, field))
        if row["primaryKey"] not in {"", "Y", "N"}:
            fail("unexpected_qc_token")
        if not row["dataType"] or row["downloadPkg"] not in {"basic", "expanded"}:
            fail("unexpected_field_class")
        categorical = row["categoricalCodeName"]
        if categorical and categorical not in categorical_rows_by_name:
            fail("unexpected_qc_token")
        declaration_rows.append(_schema_row(
            record_kind="field_declaration",
            metadata_family="variables_00130",
            file_name=payloads["variables_00130"][0].file_name,
            metadata_sha256=sha256_bytes(payloads["variables_00130"][1]),
            table_name=table,
            field_name=field,
            declared_data_type=row["dataType"],
            declared_units=row["units"],
            declared_download_package=row["downloadPkg"],
            declared_publication_format=row["pubFormat"],
            declared_primary_key=row["primaryKey"],
            declared_categorical_code=categorical,
        ))
    declared = {(row["table_name"], row["field_name"]) for row in declaration_rows}
    for table, fields in REQUIRED_FIELDS.items():
        missing = {(table, field) for field in fields} - declared
        if missing:
            fail("required_field_missing")

    validation_rows: list[dict[str, object]] = []
    validation_identities: set[tuple[str, ...]] = set()
    for row in parsed["validation_00130"]:
        table = row["table"]
        field = row["fieldName"]
        identity = (
            table, field, row["dataType"], row["units"], row["parserToCreate"],
            row["entryValidationRulesParser"], row["entryValidationRulesForm"],
        )
        if (
            not field
            or (table, field) not in declared
            or not row["dataType"]
            or not any(identity[4:])
        ):
            fail("unexpected_field_class")
        if identity in validation_identities:
            fail("duplicate_source_key")
        validation_identities.add(identity)
        validation_rows.append(_schema_row(
            record_kind="validation_rule",
            metadata_family="validation_00130",
            file_name=payloads["validation_00130"][0].file_name,
            metadata_sha256=sha256_bytes(payloads["validation_00130"][1]),
            table_name=table,
            field_name=field,
            declared_data_type=row["dataType"],
            declared_units=row["units"],
            validation_parser=row["parserToCreate"],
            validation_rule_parser=row["entryValidationRulesParser"],
            validation_rule_form=row["entryValidationRulesForm"],
        ))

    normalized_categorical_rows: list[dict[str, object]] = []
    for row in parsed["categoricalCodes_00130"]:
        normalized_categorical_rows.append(_schema_row(
            record_kind="categorical_code",
            metadata_family="categoricalCodes_00130",
            file_name=payloads["categoricalCodes_00130"][0].file_name,
            metadata_sha256=sha256_bytes(
                payloads["categoricalCodes_00130"][1],
            ),
            declared_categorical_code=row["name"],
            categorical_pub_code=row["pubCode"],
            categorical_start_date=row["startDate"],
            categorical_end_date=row["endDate"],
        ))

    validation_keys = {
        (str(row["table_name"]), str(row["field_name"]))
        for row in validation_rows
    }
    categorical_keys = {
        (str(row["table_name"]), str(row["field_name"]))
        for row in declaration_rows
        if row["declared_categorical_code"]
    }
    if not QC_FIELD_KEYS.issubset(validation_keys | categorical_keys):
        fail("unexpected_qc_token")

    return sorted(
        schema_rows + declaration_rows + validation_rows + normalized_categorical_rows,
        key=lambda row: tuple(str(row[column]) for column in SCHEMA_COLUMNS),
    )


def verify_ledger(path: Path) -> dict[str, object]:
    if path.is_symlink() or not path.is_file() or sha256_file(path) != LEDGER_SHA256:
        fail("response_authority_mismatch")
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError):
        fail("response_authority_mismatch")
    if not lines or lines[0] != "siteID\tutc_calendar_year":
        fail("response_authority_mismatch")
    keys: list[tuple[str, int]] = []
    for line in lines[1:]:
        fields = line.split("\t")
        if len(fields) != 2 or fields[0] not in ROSTER or not re.fullmatch(r"[0-9]{4}", fields[1]):
            fail("response_authority_mismatch")
        keys.append((fields[0], int(fields[1])))
    if keys != sorted(keys) or len(keys) != len(set(keys)) or len(keys) != LEDGER_ROWS:
        fail("response_210_24_23_mismatch")
    counts = {site: 0 for site in ROSTER}
    for site, _ in keys:
        counts[site] += 1
    if len([site for site, count in counts.items() if count >= 6]) != LEDGER_SITES_GE_6:
        fail("response_210_24_23_mismatch")
    return {
        "git_blob": LEDGER_BLOB,
        "sha256": LEDGER_SHA256,
        "row_count": LEDGER_ROWS,
        "site_count": LEDGER_SITES,
        "sites_with_at_least_six_years": LEDGER_SITES_GE_6,
    }


def verify_driver_hashes(root: Path) -> dict[str, str]:
    output: dict[str, str] = {}
    for label, relative in CANONICAL_DRIVER_PATHS.items():
        path = root / relative
        if path.is_symlink() or not path.is_file():
            fail("driver_artifact_changed")
        actual = sha256_file(path)
        if actual != CANONICAL_DRIVER_HASHES[label]:
            fail("driver_artifact_changed")
        output[label] = actual
    return output


def canonical_tsv(columns: Sequence[str], rows: Iterable[Mapping[str, object]]) -> bytes:
    output = io.StringIO(newline="")
    output.write("\t".join(columns) + "\n")
    for row in rows:
        if set(row) != set(columns):
            fail("receipt_schema_mismatch")
        values: list[str] = []
        for column in columns:
            value = row[column]
            if type(value) is bool or value is None:
                fail("receipt_schema_mismatch")
            text = str(value)
            if any(char in text for char in "\t\r\n\x00"):
                fail("credential_or_capability_exposed")
            values.append(text)
        output.write("\t".join(values) + "\n")
    return output.getvalue().encode("utf-8")


def canonical_json(value: Mapping[str, object]) -> bytes:
    try:
        return (json.dumps(value, sort_keys=True, indent=2, ensure_ascii=True) + "\n").encode("ascii")
    except (TypeError, ValueError):
        fail("receipt_schema_mismatch")


FORBIDDEN_ROUTE_MARKERS = (
    b"http://", b"https://", b"X-API-Token", b"Authorization", b"Bearer ",
    b"X-Amz-", b"GoogleAccessId", b"Signature=", b"Credential=",
)


def assert_route_free(raw: bytes) -> None:
    lowered = raw.lower()
    if any(marker.lower() in lowered for marker in FORBIDDEN_ROUTE_MARKERS):
        fail("credential_or_capability_exposed")
    if b"?" in raw or b"\\u003f" in lowered:
        fail("credential_or_capability_exposed")


def schema_detail_receipt(
    schema_rows: Sequence[Mapping[str, object]],
) -> dict[str, dict[str, object]]:
    metadata_rows: dict[str, Mapping[str, object]] = {}
    for row in schema_rows:
        if row.get("record_kind") != "metadata_file":
            continue
        family = row.get("metadata_family")
        if not isinstance(family, str) or family in metadata_rows:
            fail("receipt_schema_mismatch")
        metadata_rows[family] = row

    output: dict[str, dict[str, object]] = {}
    for family, record_kind in SCHEMA_DETAIL_KINDS.items():
        metadata = metadata_rows.get(family)
        if metadata is None:
            fail("receipt_schema_mismatch")
        metadata_count = metadata.get("metadata_row_count")
        metadata_sha256 = metadata.get("metadata_sha256")
        if (
            type(metadata_count) is not int
            or metadata_count < 0
            or not isinstance(metadata_sha256, str)
            or HEX64.fullmatch(metadata_sha256) is None
        ):
            fail("receipt_schema_mismatch")
        detail_rows = [
            row for row in schema_rows
            if row.get("record_kind") == record_kind
            and row.get("metadata_family") == family
        ]
        if len(detail_rows) != metadata_count:
            fail("receipt_schema_mismatch")
        detail_raw = canonical_tsv(SCHEMA_COLUMNS, detail_rows)
        output[family] = {
            "record_kind": record_kind,
            "metadata_sha256": metadata_sha256,
            "metadata_row_count": metadata_count,
            "detail_row_count": len(detail_rows),
            "detail_sha256": sha256_bytes(detail_raw),
        }
    return output


def build_receipt_bytes(
    *,
    source_sha: str,
    availability_sha256: str,
    records: Sequence[FileRecord],
    schema_rows: Sequence[Mapping[str, object]],
    ledger_receipt: Mapping[str, object],
    driver_hashes: Mapping[str, str],
) -> dict[str, bytes]:
    if HEX40.fullmatch(source_sha) is None or HEX64.fullmatch(availability_sha256) is None:
        fail("revision_identity_mismatch")
    if dict(driver_hashes) != CANONICAL_DRIVER_HASHES:
        fail("driver_artifact_changed")

    inventory_rows = [record.inventory_row() for record in records]
    allowlist_rows = [
        record.allowlist_row() for record in records
        if record.file_role == "f2_identity_only"
    ]
    if not allowlist_rows or {row["table_family"] for row in allowlist_rows} != set(MAIN_TABLES):
        fail("required_table_missing")
    inventory_raw = canonical_tsv(FILE_INVENTORY_COLUMNS, inventory_rows)
    schema_raw = canonical_tsv(SCHEMA_COLUMNS, schema_rows)
    allowlist_raw = canonical_tsv(ALLOWLIST_COLUMNS, allowlist_rows)
    schema_detail = schema_detail_receipt(schema_rows)

    roster_digest = sha256_bytes(("\n".join(ROSTER) + "\n").encode("ascii"))
    receipt = {
        "schema_version": CONTRACT_VERSION,
        "gate": "F1_METADATA_INVENTORY",
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
        "response_authority": dict(ledger_receipt),
        "schema_detail": schema_detail,
        "inventory": {
            "file_inventory_rows": len(inventory_rows),
            "schema_inventory_rows": len(schema_rows),
            "f2_allowlist_rows": len(allowlist_rows),
            "metadata_files_fetched": len(REQUIRED_METADATA),
            "other_observation_files_excluded": sum(
                record.file_role in {"other_observation_excluded", "known_special_excluded"}
                for record in records
            ),
            "file_inventory_sha256": sha256_bytes(inventory_raw),
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
        "driver_hashes": dict(driver_hashes),
    }
    release_raw = canonical_json(receipt)
    outputs = {
        "discharge-f1-release-receipt.json": release_raw,
        "discharge-f1-file-inventory.tsv": inventory_raw,
        "discharge-f1-schema-inventory.tsv": schema_raw,
        "discharge-f2-file-allowlist.tsv": allowlist_raw,
    }
    for raw in outputs.values():
        assert_route_free(raw)
    return outputs
