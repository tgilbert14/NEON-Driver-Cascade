#!/usr/bin/env python3
"""Networkless adversarial fixtures for the Discharge F1 boundary."""

from __future__ import annotations

import ast
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

import discharge_f1_acquire as acquire
import discharge_f1_contract as contract
import verify_discharge_f1_inventory as verifier


REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_SHA = "a" * 40
SECRET_SENTINEL = "fixture-secret-must-never-escape-123456"
OBSERVATION_CANARY = "https://observation-canary.invalid/must-never-be-read?secret=1"


def classify_fixture(
    name: str,
    *,
    domain: str = "D01",
    site: str = "ARIK",
    month: str = "2020-01",
    generation: str = contract.RELEASE_GENERATION_UTC,
):
    return contract.classify_filename(
        name,
        domain_code=domain,
        site_id=site,
        year_month=month,
        package_generation_utc=generation,
    )


def expect_error(code: str, action, label: str) -> None:
    try:
        action()
    except contract.F1Error as error:
        assert error.code == code, f"{label}: expected {code}, received {error.code}"
        assert SECRET_SENTINEL not in str(error), f"{label}: secret entered error"
        return
    raise AssertionError(f"contract accepted {label}")


def expect_verification_error(code: str, action, label: str) -> None:
    try:
        action()
    except verifier.VerificationError as error:
        assert error.code == code, f"{label}: expected {code}, received {error.code}"
        assert SECRET_SENTINEL not in str(error), f"{label}: secret entered verifier error"
        return
    raise AssertionError(f"verifier accepted {label}")


def csv_bytes(header: tuple[str, ...], rows: list[tuple[str, ...]]) -> bytes:
    lines = [",".join(header)]
    lines.extend(",".join(row) for row in rows)
    return ("\n".join(lines) + "\n").encode("utf-8")


def variable_payload() -> bytes:
    rows: list[tuple[str, ...]] = []
    types = {
        "siteID": "string",
        "namedLocation": "string",
        "endDateTime": "dateTime",
        "endDate": "dateTime",
        "dischargeContinuous": "real",
        "maxpostDischarge": "real",
        "dischargeFinalQF": "integer",
        "dischargeFinalQFSciRvw": "integer",
        "dischargeCorrectionApplied": "integer",
    }
    for table, fields in contract.REQUIRED_FIELDS.items():
        for field in fields:
            units = "litersPerSecond" if field in {"dischargeContinuous", "maxpostDischarge"} else ""
            categorical = (
                "binaryFlag_00130"
                if (table, field) in contract.QC_FIELD_KEYS
                else ""
            )
            rows.append((
                table, field, "fixture metadata only", types[field], units,
                "basic", types[field], "N", categorical,
            ))
    rows.append((
        "csd_15_min", "diagnosticExtra", "non-required completeness canary",
        "real", "", "basic", "real", "N", "",
    ))
    return csv_bytes(contract.METADATA_HEADERS["variables_00130"], rows)


def metadata_payloads() -> dict[str, bytes]:
    validation_rows = [
        (
            table, field, "fixture flag validation", "integer", "",
            "parse_integer", "value_0_or_1", "value_0_or_1",
        )
        for table, field in sorted(contract.QC_FIELD_KEYS)
    ]
    return {
        "variables_00130": variable_payload(),
        "validation_00130": csv_bytes(
            contract.METADATA_HEADERS["validation_00130"], validation_rows
        ),
        "categoricalCodes_00130": csv_bytes(
            contract.METADATA_HEADERS["categoricalCodes_00130"], [
                ("binaryFlag_00130", "0", "clear", "", ""),
                ("binaryFlag_00130", "1", "raised", "", ""),
            ]
        ),
        "readme_00130": b"Continuous Discharge metadata fixture.\n",
        "issueLog_00130": csv_bytes(
            contract.METADATA_HEADERS["issueLog_00130"], []
        ),
    }


def metadata_filename(family: str) -> str:
    extension = "txt" if family == "readme_00130" else "csv"
    return f"NEON.DP4.00130.001.{family}.20260123T000000Z.{extension}"


def file_item(name: str, raw: bytes, route: str | None = None) -> dict:
    return {
        "name": name,
        "size": len(raw),
        "md5": contract.md5_bytes(raw),
        "crc32c": acquire.crc32c_hex(raw),
        "url": route or f"https://storage.googleapis.com/neon-fixture/{name}?X-Goog-Signature=fixture",
    }


def observation_item(table: str, site: str = "ARIK", month: str = "2020-01") -> dict:
    name = (
        f"NEON.D01.{site}.DP4.00130.001.{table}.{month}."
        "expanded.20260123T000000Z.csv"
    )
    return {
        "name": name,
        "size": 999,
        "md5": "1" * 32,
        "crc32c": "2" * 8,
        "url": OBSERVATION_CANARY,
    }


def query_payload(*, reverse: bool = False) -> dict:
    payloads = metadata_payloads()
    files = [
        file_item(metadata_filename(family), raw)
        for family, raw in payloads.items()
    ]
    files.extend([
        observation_item("csd_15_min"),
        observation_item("csd_continuousDischarge"),
        observation_item("csd_gaugeWaterColumnRegression"),
    ])
    if reverse:
        files.reverse()
    return {
        "data": {
            "productCode": contract.PRODUCT_CODE,
            "siteCodes": list(reversed(contract.ROSTER)) if reverse else list(contract.ROSTER),
            "startDate": contract.REQUEST_START_UTC,
            "endDate": contract.REQUEST_END_UTC,
            "packageType": contract.PACKAGE_TYPE,
            "releases": [{
                "release": contract.RELEASE_TAG,
                "generationDate": contract.RELEASE_GENERATION_UTC,
                "packages": [{
                    "domainCode": "D01",
                    "siteCode": "ARIK",
                    "month": "2020-01",
                    "packageType": contract.PACKAGE_TYPE,
                    "generationDate": contract.RELEASE_GENERATION_UTC,
                    "files": files,
                }],
            }],
        },
    }


def release_payload(availability_name: str, availability_size: int, availability_md5: str) -> dict:
    return {
        "data": {
            "release": contract.RELEASE_TAG,
            "uuid": contract.RELEASE_UUID,
            "generationDate": contract.RELEASE_GENERATION_UTC,
            "artifacts": [{
                "name": availability_name,
                "type": "availability",
                "size": availability_size,
                "md5": availability_md5,
                "url": (
                    f"https://storage.googleapis.com/neon-fixture/{availability_name}"
                    "?X-Goog-Signature=fixture"
                ),
            }],
            "dataProducts": [{
                "productCode": contract.PRODUCT_CODE,
                "productDescription": "fixture",
                "productDoi": f"https://doi.org/{contract.PRODUCT_DOI}",
                "productName": contract.PRODUCT_NAME,
            }],
        },
    }


def records_and_schema() -> tuple[list[contract.FileRecord], list[dict[str, object]]]:
    records = contract.validate_query_payload(query_payload())
    payloads = metadata_payloads()
    downloads = contract.unique_metadata_downloads(records)
    by_family = {record.logical_family: (record, payloads[record.logical_family]) for record in downloads}
    schema = contract.inspect_metadata(by_family)
    return records, schema


def write_receipt_family(
    root: Path,
    outputs: dict[str, bytes],
    *,
    mode: int = 0o600,
) -> None:
    root.mkdir(mode=0o700)
    for name, raw in outputs.items():
        target = root / name
        target.write_bytes(raw)
        target.chmod(mode)


def coherent_receipt_mutation(
    outputs: dict[str, bytes],
    *,
    inventory_rows: list[dict[str, str]] | None = None,
    schema_rows: list[dict[str, str]] | None = None,
) -> dict[str, bytes]:
    mutated = dict(outputs)
    receipt = json.loads(mutated[verifier.RECEIPT_NAME])
    if inventory_rows is not None:
        inventory_rows.sort(key=lambda row: (
            row["site_id"], row["year_month"], row["domain_code"],
            row["package_generation_utc"], row["file_role"],
            row["logical_family"], row["file_name"],
            row["file_generation_utc"], row["md5"], row["crc32c"],
        ))
        inventory_raw = contract.canonical_tsv(
            verifier.FILE_INVENTORY_COLUMNS, inventory_rows,
        )
        allowlist_rows = verifier.expected_allowlist_rows(inventory_rows)
        allowlist_raw = contract.canonical_tsv(
            verifier.ALLOWLIST_COLUMNS, allowlist_rows,
        )
        mutated[verifier.FILE_INVENTORY_NAME] = inventory_raw
        mutated[verifier.ALLOWLIST_NAME] = allowlist_raw
        receipt["inventory"]["file_inventory_rows"] = len(inventory_rows)
        receipt["inventory"]["f2_allowlist_rows"] = len(allowlist_rows)
        receipt["inventory"]["file_inventory_sha256"] = contract.sha256_bytes(
            inventory_raw,
        )
        receipt["inventory"]["f2_allowlist_sha256"] = contract.sha256_bytes(
            allowlist_raw,
        )
    if schema_rows is not None:
        schema_rows.sort(
            key=lambda row: tuple(row[column] for column in verifier.SCHEMA_COLUMNS),
        )
        schema_raw = contract.canonical_tsv(verifier.SCHEMA_COLUMNS, schema_rows)
        mutated[verifier.SCHEMA_INVENTORY_NAME] = schema_raw
        receipt["inventory"]["schema_inventory_rows"] = len(schema_rows)
        receipt["inventory"]["schema_inventory_sha256"] = contract.sha256_bytes(
            schema_raw,
        )
        metadata_rows = {
            row["metadata_family"]: row
            for row in schema_rows
            if row["record_kind"] == "metadata_file"
        }
        for family, record_kind in verifier.SCHEMA_DETAIL_KINDS.items():
            metadata = metadata_rows[family]
            detail_rows = [
                row for row in schema_rows
                if row["record_kind"] == record_kind
                and row["metadata_family"] == family
            ]
            detail_raw = contract.canonical_tsv(
                verifier.SCHEMA_COLUMNS, detail_rows,
            )
            receipt["schema_detail"][family] = {
                "record_kind": record_kind,
                "metadata_sha256": metadata["metadata_sha256"],
                "metadata_row_count": int(metadata["metadata_row_count"]),
                "detail_row_count": len(detail_rows),
                "detail_sha256": contract.sha256_bytes(detail_raw),
            }
    mutated[verifier.RECEIPT_NAME] = contract.canonical_json(receipt)
    return mutated


def exercise_coherent_verifier_mutations(
    outputs: dict[str, bytes],
    parent: Path,
) -> None:
    inventory_rows = verifier.parse_tsv(
        outputs[verifier.FILE_INVENTORY_NAME], verifier.FILE_INVENTORY_COLUMNS,
    )
    split_package = copy.deepcopy(inventory_rows)
    target = next(
        row for row in split_package if row["logical_family"] == "csd_15_min"
    )
    target["domain_code"] = "D02"
    target["file_name"] = target["file_name"].replace(".D01.", ".D02.", 1)
    split_outputs = coherent_receipt_mutation(
        outputs, inventory_rows=split_package,
    )
    split_root = parent / "split-package"
    write_receipt_family(split_root, split_outputs)
    expect_verification_error(
        "inventory_contract_mismatch",
        lambda: verifier.verify(split_root),
        "split package identity",
    )

    schema_rows = verifier.parse_tsv(
        outputs[verifier.SCHEMA_INVENTORY_NAME], verifier.SCHEMA_COLUMNS,
    )
    deletion_cases = {
        "field declaration": lambda row: not (
            row["record_kind"] == "field_declaration"
            and row["field_name"] == "diagnosticExtra"
        ),
        "validation rule": lambda row: not (
            row["record_kind"] == "validation_rule"
            and row["field_name"] == "dischargeFinalQF"
        ),
        "categorical code": lambda row: not (
            row["record_kind"] == "categorical_code"
            and row["categorical_pub_code"] == "1"
        ),
    }
    for index, (label, retain) in enumerate(deletion_cases.items()):
        reduced = [row for row in copy.deepcopy(schema_rows) if retain(row)]
        assert len(reduced) < len(schema_rows)
        reduced_outputs = coherent_receipt_mutation(outputs, schema_rows=reduced)
        reduced_root = parent / f"schema-deletion-{index}"
        write_receipt_family(reduced_root, reduced_outputs)
        expect_verification_error(
            "schema_contract_mismatch",
            lambda root=reduced_root: verifier.verify(root),
            f"coherent {label} deletion",
        )

    receipt = json.loads(outputs[verifier.RECEIPT_NAME])
    receipt["request"]["start_utc"] = "2016-08-01T00:00:01Z"
    utc_outputs = dict(outputs)
    utc_outputs[verifier.RECEIPT_NAME] = contract.canonical_json(receipt)
    utc_root = parent / "utc-boundary-mutation"
    write_receipt_family(utc_root, utc_outputs)
    expect_verification_error(
        "receipt_contract_mismatch",
        lambda: verifier.verify(utc_root),
        "exact request UTC mutation",
    )


def exercise_json_and_release() -> None:
    expect_error(
        "duplicate_json_key",
        lambda: contract.strict_json_loads(b'{"data":1,"data":2}', max_bytes=100),
        "duplicate JSON keys",
    )
    expect_error(
        "forbidden_json_constant",
        lambda: contract.strict_json_loads(b'{"data":NaN}', max_bytes=100),
        "non-finite JSON constant",
    )
    expect_error(
        "malformed_or_oversized_json",
        lambda: contract.strict_json_loads(b"{}", max_bytes=1),
        "oversized JSON",
    )
    valid = release_payload(
        contract.AVAILABILITY_NAME,
        contract.AVAILABILITY_BYTES,
        contract.AVAILABILITY_MD5,
    )
    authority = contract.validate_release_payload(valid)
    assert contract.AVAILABILITY_NAME in authority.availability_route
    for label, mutate in {
        "release UUID": lambda value: value["data"].__setitem__("uuid", "wrong"),
        "generation": lambda value: value["data"].__setitem__("generationDate", "2026-01-23T00:07:50Z"),
        "DOI": lambda value: value["data"]["dataProducts"][0].__setitem__("productDoi", "10.invalid/test"),
        "manifest size": lambda value: value["data"]["artifacts"][0].__setitem__("size", 1),
        "manifest MD5": lambda value: value["data"]["artifacts"][0].__setitem__("md5", "0" * 32),
    }.items():
        drift = copy.deepcopy(valid)
        mutate(drift)
        expect_error("release_identity_mismatch", lambda value=drift: contract.validate_release_payload(value), label)
    route_drift = copy.deepcopy(valid)
    route_drift["data"]["artifacts"][0]["url"] = "http://storage.googleapis.com/file"
    expect_error(
        "manifest_allowlist_mismatch",
        lambda: contract.validate_release_payload(route_drift),
        "HTTPS downgrade",
    )


def exercise_filename_classifier() -> None:
    assert classify_fixture(observation_item("csd_15_min")["name"]) == (
        "f2_identity_only", "csd_15_min", "2026-01-23T00:00:00Z",
    )
    assert classify_fixture(
        observation_item("csd_gaugeWaterColumnRegression")["name"],
    ) == (
        "other_observation_excluded", "csd_gaugeWaterColumnRegression",
        "2026-01-23T00:00:00Z",
    )
    assert classify_fixture(metadata_filename("variables_00130")) == (
        "metadata_bytes_allowed", "variables_00130", "2026-01-23T00:00:00Z",
    )
    cases = {
        "path traversal": "../NEON.DP4.00130.001.variables_00130.csv",
        "double extension": observation_item("csd_15_min")["name"] + ".gz",
        "case near-match": observation_item("csd_15_min")["name"].replace("csd_15_min", "CSd_15_min"),
        "table suffix": observation_item("csd_15_min")["name"].replace("csd_15_min", "csd_15_min_v2"),
        "unknown metadata": metadata_filename("variables_00130").replace("variables_00130", "mystery_00130"),
        "query basename": metadata_filename("variables_00130") + "?token=bad",
        "archive": metadata_filename("variables_00130") + ".zip",
        "site-month metadata masquerade": (
            "NEON.D01.ARIK.DP4.00130.001.private_values.variables_00130."
            "2020-01.expanded.20260123T000000Z.csv"
        ),
        "conflicting observation site": observation_item("csd_15_min")["name"].replace(
            "ARIK.DP4", "ARIK.BLUE.DP4",
        ),
        "conflicting observation month": observation_item("csd_15_min")["name"].replace(
            "2020-01.expanded", "2020-01.2019-01.expanded",
        ),
        "conflicting observation domain": observation_item("csd_15_min")["name"].replace(
            "NEON.D01", "NEON.D02",
        ),
        "conflicting observation package": observation_item("csd_15_min")["name"].replace(
            ".expanded.", ".basic.",
        ),
    }
    for label, name in cases.items():
        expect_error(
            "manifest_allowlist_mismatch",
            lambda value=name: classify_fixture(value),
            label,
        )
    expect_error(
        "provisional_input_present",
        lambda: classify_fixture(
            observation_item("csd_15_min", month="2024-10")["name"],
            month="2024-10",
        ),
        "post-release month",
    )
    expect_error(
        "manifest_allowlist_mismatch",
        lambda: classify_fixture(
            observation_item("csd_15_min", site="TOMB")["name"],
            site="TOMB",
        ),
        "TOMB injection",
    )
    expect_error(
        "manifest_allowlist_mismatch",
        lambda: classify_fixture(
            observation_item("csd_15_min", month="2016-07")["name"],
            month="2016-07",
        ),
        "pre-release-window month",
    )


def exercise_query_contract() -> None:
    records = contract.validate_query_payload(query_payload())
    assert {record.logical_family for record in records if record.file_role == "f2_identity_only"} == set(contract.MAIN_TABLES)
    assert all(record.route is None for record in records if "observation" in record.file_role or record.file_role == "f2_identity_only")
    assert OBSERVATION_CANARY not in repr(records)
    assert records == contract.validate_query_payload(query_payload(reverse=True))

    mutations = []
    wrong_roster = query_payload()
    wrong_roster["data"]["siteCodes"][-1] = "TOMB"
    mutations.append(("response_210_24_23_mismatch", wrong_roster, "roster mutation"))
    basic = query_payload()
    basic["data"]["packageType"] = "basic"
    mutations.append(("package_not_expanded", basic, "basic package"))
    wrong_start = query_payload()
    wrong_start["data"]["startDate"] = "2016-09-01T00:00:00Z"
    mutations.append(("release_identity_mismatch", wrong_start, "response start drift"))
    wrong_end = query_payload()
    wrong_end["data"]["endDate"] = "2024-09-30T23:59:58Z"
    mutations.append(("release_identity_mismatch", wrong_end, "response end drift"))
    bad_generation = query_payload()
    bad_generation["data"]["releases"][0]["packages"][0]["generationDate"] = "garbage"
    mutations.append(("release_identity_mismatch", bad_generation, "malformed package generation"))
    impossible_generation = query_payload()
    impossible_generation["data"]["releases"][0]["packages"][0]["generationDate"] = "2020-99-99T99:99:99Z"
    mutations.append(("release_identity_mismatch", impossible_generation, "impossible package generation"))
    future_generation = query_payload()
    future_generation["data"]["releases"][0]["packages"][0]["generationDate"] = "2026-01-23T00:07:50Z"
    mutations.append(("release_identity_mismatch", future_generation, "post-release package generation"))
    early_generation = query_payload()
    early_generation["data"]["releases"][0]["packages"][0]["generationDate"] = "2019-12-31T23:59:59Z"
    mutations.append(("release_identity_mismatch", early_generation, "pre-data package generation"))
    provisional = query_payload()
    provisional["data"]["releases"][0]["packages"][0]["month"] = "2024-10"
    mutations.append(("provisional_input_present", provisional, "post-release package"))
    pre_window = query_payload()
    pre_window["data"]["releases"][0]["packages"][0]["month"] = "2016-07"
    mutations.append(("manifest_allowlist_mismatch", pre_window, "pre-window package"))
    duplicate_package = query_payload()
    duplicate_package["data"]["releases"][0]["packages"].append(
        copy.deepcopy(duplicate_package["data"]["releases"][0]["packages"][0])
    )
    mutations.append(("duplicate_source_key", duplicate_package, "duplicate package"))
    duplicate_file = query_payload()
    files = duplicate_file["data"]["releases"][0]["packages"][0]["files"]
    files.append(copy.deepcopy(files[0]))
    mutations.append(("duplicate_source_key", duplicate_file, "duplicate file"))
    missing_metadata = query_payload()
    files = missing_metadata["data"]["releases"][0]["packages"][0]["files"]
    files[:] = [item for item in files if "issueLog_00130" not in item["name"]]
    mutations.append(("required_table_missing", missing_metadata, "missing metadata family"))
    disguised = query_payload()
    files = disguised["data"]["releases"][0]["packages"][0]["files"]
    files[0]["name"] = files[0]["name"].replace("variables_00130", "variables_00130.csd_15_min")
    mutations.append(("manifest_allowlist_mismatch", disguised, "metadata-observation masquerade"))
    for code, value, label in mutations:
        expect_error(code, lambda candidate=value: contract.validate_query_payload(candidate), label)


def exercise_metadata_contract() -> None:
    records, schema = records_and_schema()
    assert {row["metadata_family"] for row in schema if row["record_kind"] == "metadata_file"} == set(contract.REQUIRED_METADATA)
    declarations = {
        (row["table_name"], row["field_name"])
        for row in schema if row["record_kind"] == "field_declaration"
    }
    for table, fields in contract.REQUIRED_FIELDS.items():
        assert {(table, field) for field in fields}.issubset(declarations)
    assert ("csd_15_min", "diagnosticExtra") in declarations
    validation_keys = {
        (row["table_name"], row["field_name"])
        for row in schema if row["record_kind"] == "validation_rule"
    }
    assert contract.QC_FIELD_KEYS.issubset(validation_keys)
    categorical = [
        row for row in schema if row["record_kind"] == "categorical_code"
    ]
    assert {
        (row["declared_categorical_code"], row["categorical_pub_code"])
        for row in categorical
    } == {("binaryFlag_00130", "0"), ("binaryFlag_00130", "1")}

    downloads = contract.unique_metadata_downloads(records)
    payloads = metadata_payloads()
    valid = {record.logical_family: (record, payloads[record.logical_family]) for record in downloads}
    missing_field = copy.deepcopy(payloads)
    text = missing_field["variables_00130"].decode("utf-8")
    lines = [line for line in text.splitlines() if ",dischargeContinuous," not in line]
    missing_field["variables_00130"] = ("\n".join(lines) + "\n").encode("utf-8")
    bad_map = {
        family: (replace_record(record, missing_field[family]))
        for family, (record, _) in valid.items()
    }
    expect_error("required_field_missing", lambda: contract.inspect_metadata(bad_map), "missing required declaration")

    duplicate = copy.deepcopy(payloads)
    lines = duplicate["variables_00130"].splitlines()
    duplicate["variables_00130"] = b"\n".join(lines + [lines[1]]) + b"\n"
    dup_map = {
        family: (replace_record(record, duplicate[family]))
        for family, (record, _) in valid.items()
    }
    expect_error("duplicate_source_key", lambda: contract.inspect_metadata(dup_map), "duplicate schema identity")

    duplicate_validation = copy.deepcopy(payloads)
    lines = duplicate_validation["validation_00130"].splitlines()
    duplicate_validation["validation_00130"] = b"\n".join(lines + [lines[1]]) + b"\n"
    duplicate_validation_map = {
        family: (replace_record(record, duplicate_validation[family]))
        for family, (record, _) in valid.items()
    }
    expect_error(
        "duplicate_source_key",
        lambda: contract.inspect_metadata(duplicate_validation_map),
        "duplicate validation rule",
    )

    missing_category = copy.deepcopy(payloads)
    missing_category["categoricalCodes_00130"] = csv_bytes(
        contract.METADATA_HEADERS["categoricalCodes_00130"], [],
    )
    missing_category_map = {
        family: (replace_record(record, missing_category[family]))
        for family, (record, _) in valid.items()
    }
    expect_error(
        "unexpected_qc_token",
        lambda: contract.inspect_metadata(missing_category_map),
        "missing referenced categorical schema",
    )

    header_drift = copy.deepcopy(payloads)
    header_drift["validation_00130"] = header_drift["validation_00130"].replace(b"table,", b"Table,", 1)
    header_map = {
        family: (replace_record(record, header_drift[family]))
        for family, (record, _) in valid.items()
    }
    expect_error("unexpected_field_class", lambda: contract.inspect_metadata(header_map), "metadata header drift")


def replace_record(record: contract.FileRecord, raw: bytes) -> tuple[contract.FileRecord, bytes]:
    return (
        contract.FileRecord(
            release=record.release,
            package_type=record.package_type,
            domain_code=record.domain_code,
            package_generation_utc=record.package_generation_utc,
            site_id=record.site_id,
            year_month=record.year_month,
            file_role=record.file_role,
            logical_family=record.logical_family,
            file_name=record.file_name,
            file_generation_utc=record.file_generation_utc,
            byte_size=len(raw),
            md5=contract.md5_bytes(raw),
            crc32c=acquire.crc32c_hex(raw),
            route=record.route,
        ),
        raw,
    )


def exercise_receipt_and_authorities() -> None:
    records, schema = records_and_schema()
    ledger = contract.verify_ledger(REPO_ROOT / "docs/receipts/discharge-inverts-response-site-years.tsv")
    hashes = contract.verify_driver_hashes(REPO_ROOT)
    outputs = contract.build_receipt_bytes(
        source_sha=SOURCE_SHA,
        availability_sha256="f" * 64,
        records=records,
        schema_rows=schema,
        ledger_receipt=ledger,
        driver_hashes=hashes,
    )
    receipt = json.loads(outputs[verifier.RECEIPT_NAME])
    assert receipt["request"]["start_utc"] == contract.REQUEST_START_UTC
    assert receipt["request"]["end_utc"] == contract.REQUEST_END_UTC
    for family, record_kind in contract.SCHEMA_DETAIL_KINDS.items():
        metadata_count = next(
            row["metadata_row_count"]
            for row in schema
            if row["record_kind"] == "metadata_file"
            and row["metadata_family"] == family
        )
        detail_count = sum(
            row["record_kind"] == record_kind
            and row["metadata_family"] == family
            for row in schema
        )
        assert metadata_count == detail_count
        assert receipt["schema_detail"][family]["detail_row_count"] == detail_count
    assert set(outputs) == set(acquire.OUTPUT_NAMES)
    joined = b"\n".join(outputs.values())
    assert OBSERVATION_CANARY.encode() not in joined
    assert SECRET_SENTINEL.encode() not in joined
    assert b"https://" not in joined and b"X-Amz" not in joined and b"?" not in joined
    expect_error(
        "credential_or_capability_exposed",
        lambda: contract.assert_route_free(b"route=https://example.invalid/?token=bad"),
        "route-bearing receipt",
    )

    with tempfile.TemporaryDirectory(prefix="discharge-f1-driver-hash-") as raw:
        root = Path(raw)
        for label, relative in contract.CANONICAL_DRIVER_PATHS.items():
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        assert contract.verify_driver_hashes(root) == contract.CANONICAL_DRIVER_HASHES
        (root / contract.CANONICAL_DRIVER_PATHS["manifest"]).write_bytes(b"mutation")
        expect_error("driver_artifact_changed", lambda: contract.verify_driver_hashes(root), "Driver artifact mutation")


class FixtureTransport:
    def __init__(self, release_raw: bytes, query_raw: bytes, availability_raw: bytes, payloads: dict[str, bytes]):
        self.release_raw = release_raw
        self.query_raw = query_raw
        self.availability_raw = availability_raw
        self.payloads = payloads
        self.metadata_calls: list[str] = []
        self.query_tokens: list[str] = []

    def api_request(self, *, method: str, path: str, body: bytes | None, token: str | None) -> bytes:
        if path == acquire.RELEASE_PATH:
            assert method == "GET" and token is None and body is None
            return self.release_raw
        assert path == acquire.QUERY_PATH and method == "POST" and token == SECRET_SENTINEL
        self.query_tokens.append(token)
        parsed = json.loads(body.decode("ascii"))
        assert parsed["siteCodes"] == list(contract.ROSTER)
        assert parsed["startDateMonth"] == contract.REQUEST_START_MONTH
        assert parsed["endDateMonth"] == contract.LAST_ALLOWED_MONTH
        assert parsed["includeProvisional"] is False
        return self.query_raw

    def exact_non_observation_request(self, *, route: str, file_name: str, byte_size: int) -> bytes:
        assert file_name == "manifest-fixture.json"
        assert byte_size == len(self.availability_raw)
        return self.availability_raw

    def metadata_request(self, record: contract.FileRecord) -> bytes:
        assert record.file_role == "metadata_bytes_allowed"
        assert record.logical_family in contract.REQUIRED_METADATA
        assert OBSERVATION_CANARY not in (record.route or "")
        self.metadata_calls.append(record.logical_family)
        return self.payloads[record.logical_family]


def exercise_full_acquisition_without_network() -> None:
    availability_raw = b'{"fixture":true}\n'
    old = (
        contract.AVAILABILITY_NAME,
        contract.AVAILABILITY_BYTES,
        contract.AVAILABILITY_MD5,
    )
    verifier_old = (
        verifier.AVAILABILITY_NAME,
        verifier.AVAILABILITY_BYTES,
        verifier.AVAILABILITY_MD5,
    )
    contract.AVAILABILITY_NAME = "manifest-fixture.json"
    contract.AVAILABILITY_BYTES = len(availability_raw)
    contract.AVAILABILITY_MD5 = contract.md5_bytes(availability_raw)
    verifier.AVAILABILITY_NAME = contract.AVAILABILITY_NAME
    verifier.AVAILABILITY_BYTES = contract.AVAILABILITY_BYTES
    verifier.AVAILABILITY_MD5 = contract.AVAILABILITY_MD5
    try:
        release_raw = json.dumps(release_payload(
            contract.AVAILABILITY_NAME,
            contract.AVAILABILITY_BYTES,
            contract.AVAILABILITY_MD5,
        )).encode("utf-8")
        query_raw = json.dumps(query_payload()).encode("utf-8")
        phase_transport = FixtureTransport(
            release_raw, query_raw, availability_raw, metadata_payloads(),
        )
        sanitized = acquire._acquire_sanitized_phase(
            token_box=[SECRET_SENTINEL], transport=phase_transport,
        )
        assert all(record.route is None for record in sanitized.records)
        assert not any(
            isinstance(value, (bytes, bytearray, memoryview))
            for row in sanitized.schema_rows
            for value in row.values()
        )
        assert SECRET_SENTINEL not in repr(sanitized)
        assert "X-Goog-Signature" not in repr(sanitized)

        masquerade_payload = query_payload()
        masquerade_file = next(
            item
            for item in masquerade_payload["data"]["releases"][0]["packages"][0]["files"]
            if "variables_00130" in item["name"]
        )
        masquerade_file["name"] = (
            "NEON.D01.ARIK.DP4.00130.001.private_values.variables_00130."
            "2020-01.expanded.20260123T000000Z.csv"
        )
        masquerade_transport = FixtureTransport(
            release_raw,
            json.dumps(masquerade_payload).encode("utf-8"),
            availability_raw,
            metadata_payloads(),
        )
        expect_error(
            "manifest_allowlist_mismatch",
            lambda: acquire._acquire_sanitized_phase(
                token_box=[SECRET_SENTINEL], transport=masquerade_transport,
            ),
            "metadata-shaped observation before GET",
        )
        assert masquerade_transport.metadata_calls == []

        transport = FixtureTransport(release_raw, query_raw, availability_raw, metadata_payloads())
        with tempfile.TemporaryDirectory(prefix="discharge-f1-acquire-") as parent_raw:
            parent = Path(parent_raw).resolve()
            output = parent / "sanitized"
            raw_root = parent / "raw"
            output.mkdir(mode=0o700)
            raw_root.mkdir(mode=0o700)
            token_box = [SECRET_SENTINEL]
            contract_outputs = acquire.acquire(
                output_dir=output,
                raw_root=raw_root,
                expected_source_sha=SOURCE_SHA,
                token_box=token_box,
                transport=transport,
                repo_root=REPO_ROOT,
            )
            assert contract_outputs is None and token_box == []
            assert not raw_root.exists()
            assert sorted(path.name for path in output.iterdir()) == sorted(acquire.OUTPUT_NAMES)
            combined = b"".join(path.read_bytes() for path in output.iterdir())
            assert SECRET_SENTINEL.encode() not in combined
            assert OBSERVATION_CANARY.encode() not in combined
            assert sorted(transport.metadata_calls) == sorted(contract.REQUIRED_METADATA)
            assert transport.query_tokens == [SECRET_SENTINEL]

            # Exercise the independent reviewer against both runner-private
            # producer output and the exact public 0644 file modes used by the
            # review branch.  The verifier deliberately shares no producer code.
            verifier.verify(output)
            published = parent / "published"
            published.mkdir(mode=0o700)
            for name in acquire.OUTPUT_NAMES:
                target = published / name
                shutil.copyfile(output / name, target)
                target.chmod(0o644)
            verifier.verify(published)

            sanitized_outputs = {
                name: (output / name).read_bytes()
                for name in acquire.OUTPUT_NAMES
            }
            exercise_coherent_verifier_mutations(sanitized_outputs, parent)

            original_cwd = Path.cwd()
            try:
                os.chdir(parent)
                expect_verification_error(
                    "authority_surface_mismatch",
                    lambda: verifier.verify(output),
                    "missing repository authority root",
                )
            finally:
                os.chdir(original_cwd)

            receipt_path = published / "discharge-f1-release-receipt.json"
            original_receipt = receipt_path.read_bytes()
            mutated_receipt = original_receipt.replace(
                b'"f2_authorized": false', b'"f2_authorized": true', 1,
            )
            assert mutated_receipt != original_receipt
            receipt_path.write_bytes(mutated_receipt)
            receipt_path.chmod(0o644)
            expect_verification_error(
                "receipt_contract_mismatch",
                lambda: verifier.verify(published),
                "mutated F2 authorization",
            )
    finally:
        (
            contract.AVAILABILITY_NAME,
            contract.AVAILABILITY_BYTES,
            contract.AVAILABILITY_MD5,
        ) = old
        (
            verifier.AVAILABILITY_NAME,
            verifier.AVAILABILITY_BYTES,
            verifier.AVAILABILITY_MD5,
        ) = verifier_old


def exercise_transport_and_source_surface() -> None:
    assert acquire.crc32c_hex(b"123456789") == "e3069283"
    redirect = acquire.MetadataRedirect("metadata.csv")
    assert redirect._checked(
        "https://storage.googleapis.com/bucket/metadata.csv?X-Goog-Signature=fixture"
    ).startswith("https://")
    expect_error(
        "manifest_allowlist_mismatch",
        lambda: redirect._checked("https://storage.googleapis.com/bucket/other.csv"),
        "redirect basename drift",
    )
    expect_error(
        "manifest_allowlist_mismatch",
        lambda: redirect._checked("https://evil.invalid/bucket/metadata.csv"),
        "redirect host drift",
    )
    source = Path(acquire.__file__).read_text(encoding="utf-8")
    tree = ast.parse(source)
    imports = {
        alias.name.split(".")[0]
        for node in ast.walk(tree)
        if isinstance(node, ast.Import)
        for alias in node.names
    }
    imports.update(
        node.module.split(".")[0]
        for node in ast.walk(tree)
        if isinstance(node, ast.ImportFrom) and node.module
    )
    assert "subprocess" not in imports
    assert "os.system" not in source and "Popen" not in source

    verifier_source = Path(verifier.__file__).read_text(encoding="utf-8")
    verifier_tree = ast.parse(verifier_source)
    verifier_imports = {
        alias.name.split(".")[0]
        for node in ast.walk(verifier_tree)
        if isinstance(node, ast.Import)
        for alias in node.names
    }
    verifier_imports.update(
        node.module.split(".")[0]
        for node in ast.walk(verifier_tree)
        if isinstance(node, ast.ImportFrom) and node.module
    )
    assert not {
        "discharge_f1_acquire", "discharge_f1_contract", "requests",
        "socket", "subprocess", "urllib",
    } & verifier_imports
    assert "os.system" not in verifier_source and "Popen" not in verifier_source


def exercise_workflow_policy() -> None:
    path = REPO_ROOT / ".github/workflows/discharge-f1-inventory.yml"
    text = path.read_text(encoding="utf-8")
    lowered = text.lower()
    assert "workflow_dispatch:" in text and "pull_request:" not in text and "schedule:" not in text
    assert "name: discharge-f1" in text
    assert text.count("${{ secrets.NEON_TOKEN }}") == 1
    assert text.count("${{ github.token }}") == 1
    assert text.count("persist-credentials: false") == 2
    assert "shell: python3 -I -S -B {0}" in text
    assert "safe_environment.clear()" in text
    assert text.count('sudo unshare --net -- sudo -u "$runner_user" env -i') == 1
    assert "upload-artifact" not in lowered and "download-artifact" not in lowered
    assert "actions/cache" not in lowered and "gh pr create" not in lowered
    assert "curl " not in lowered and "wget " not in lowered and "set -x" not in lowered
    assert "refs/heads/master:refs/heads/master" not in text
    assert text.index("Acquire only the authenticated F1 metadata inventory") < text.index("Destroy the exact raw acquisition root")
    assert text.index("Destroy the exact raw acquisition root") < text.index("Independently verify the sanitized family")
    assert text.index("Independently verify the sanitized family") < text.index("Checkout a fresh publication worktree")
    assert text.index("Checkout a fresh publication worktree") < text.index("Push one unique direct-child review branch")

    ci_text = (REPO_ROOT / ".github/workflows/ci.yml").read_text(
        encoding="utf-8",
    )
    assert ci_text.count(
        'sudo unshare --net -- sudo -u "$runner_user" env -i',
    ) >= 1
    assert "Bind any F1 receipt family to its direct-child producer" in ci_text
    assert "automation/discharge-f1-[0-9]+-[0-9]+" in ci_text


def main() -> None:
    exercise_json_and_release()
    exercise_filename_classifier()
    exercise_query_contract()
    exercise_metadata_contract()
    exercise_receipt_and_authorities()
    exercise_full_acquisition_without_network()
    exercise_transport_and_source_surface()
    exercise_workflow_policy()
    print("OK: Discharge F1 offline contract and adversarial fixtures passed.")


if __name__ == "__main__":
    main()
