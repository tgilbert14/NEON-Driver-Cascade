#!/usr/bin/env python3
"""Adversarial, standard-library-only fixtures for the publisher boundary."""

from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

import trusted_publish as guard


REPO_ROOT = Path(__file__).resolve().parent.parent
BASE_SHA = "0" * 40


def expect_rejection(action, label: str) -> None:
    try:
        action()
    except SystemExit:
        return
    raise AssertionError(f"guard accepted {label}")


def copy_deploy_root(destination: Path) -> dict:
    for relative in guard.DEPLOY_FILES:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO_ROOT / relative, target)
    manifest = guard.read_json(REPO_ROOT / "manifest.json")
    for relative in guard.DEPLOY_FILES:
        manifest["files"][relative]["checksum"] = guard.file_digest(
            destination / relative, "md5"
        )
    return manifest


def exercise_manifest_policy() -> None:
    assert "jsonlite" in guard.DIRECT_PACKAGES
    assert not guard.trusted_repository(
        "https://packagemanager.posit.co/cran/path with space"
    )
    with tempfile.TemporaryDirectory(prefix="cascade-publisher-manifest-") as raw:
        root = Path(raw)
        manifest = copy_deploy_root(root)
        guard.validate_manifest(manifest, root, check_checksums=True)

        implicit = copy.deepcopy(manifest)
        for record in implicit["packages"].values():
            for field in guard.STANDARD_REMOTE_FIELDS:
                record["description"].pop(field, None)
            record["description"]["Repository"] = "CRAN"
        guard.validate_manifest(implicit, root, check_checksums=True)

        explicit_cran = copy.deepcopy(implicit)
        for name, record in explicit_cran["packages"].items():
            description = record["description"]
            description.update({
                "RemoteType": "standard",
                "RemoteRepos": "https://cran.r-project.org",
                "RemotePkgRef": name,
                "RemoteRef": name,
                "RemoteSha": description["Version"],
            })
        guard.validate_manifest(explicit_cran, root, check_checksums=True)

        approved_platform = next(iter(guard.ALLOWED_REMOTE_PKG_PLATFORMS))
        explicit_rspm = copy.deepcopy(explicit_cran)
        for record in explicit_rspm["packages"].values():
            record["Repository"] = guard.CANONICAL_RSPM_REPOSITORY
            description = record["description"]
            description["Repository"] = "RSPM"
            description["RemoteRepos"] = guard.CANONICAL_RSPM_REPOSITORY
            description["RemotePkgPlatform"] = approved_platform
            description["Built"] = (
                "R 4.5.9; x86_64-pc-linux-gnu; "
                "2030-01-01 00:00:00 UTC; unix"
            )
        guard.validate_manifest(explicit_rspm, root, check_checksums=True)

        rspm_without_platform = copy.deepcopy(explicit_rspm)
        for record in rspm_without_platform["packages"].values():
            record["description"].pop("RemotePkgPlatform")
        guard.validate_manifest(rspm_without_platform, root, check_checksums=True)

        package = next(iter(explicit_cran["packages"]))
        for field in guard.STANDARD_REMOTE_CORE_FIELDS:
            partial = copy.deepcopy(explicit_cran)
            partial["packages"][package]["description"].pop(field)
            expect_rejection(
                lambda candidate=partial: guard.validate_manifest(
                    candidate, root, check_checksums=True
                ),
                f"explicit provenance missing {field}",
            )
            singleton = copy.deepcopy(implicit)
            singleton["packages"][package]["description"][field] = (
                explicit_cran["packages"][package]["description"][field]
            )
            expect_rejection(
                lambda candidate=singleton: guard.validate_manifest(
                    candidate, root, check_checksums=True
                ),
                f"singleton provenance field {field}",
            )

        platform_only = copy.deepcopy(implicit)
        platform_only["packages"][package]["description"]["RemotePkgPlatform"] = (
            approved_platform
        )
        expect_rejection(
            lambda: guard.validate_manifest(platform_only, root, check_checksums=True),
            "platform metadata without core provenance",
        )
        null_platform = copy.deepcopy(explicit_rspm)
        null_platform["packages"][package]["description"]["RemotePkgPlatform"] = None
        expect_rejection(
            lambda: guard.validate_manifest(null_platform, root, check_checksums=True),
            "a named null platform field",
        )
        invalid_platforms = {
            "empty": "",
            "list": [approved_platform],
            "wrong OS": "aarch64-apple-darwin20",
            "near miss": "x86_64-pc-linux-gnu-ubuntu-24.04.1",
            "whitespace": "x86_64-pc-linux-gnu-ubuntu-24.04 ",
        }
        for label, value in invalid_platforms.items():
            invalid = copy.deepcopy(explicit_rspm)
            invalid["packages"][package]["description"]["RemotePkgPlatform"] = value
            expect_rejection(
                lambda candidate=invalid: guard.validate_manifest(
                    candidate, root, check_checksums=True
                ),
                f"invalid platform value {label}",
            )

        null_field = copy.deepcopy(explicit_cran)
        null_field["packages"][package]["description"]["RemoteType"] = None
        expect_rejection(
            lambda: guard.validate_manifest(null_field, root, check_checksums=True),
            "a named null provenance field",
        )
        invalid_values = {
            "RemoteType": "github",
            "RemoteRepos": "https://example.invalid/cran",
            "RemotePkgRef": "wrong-package",
            "RemoteRef": "wrong-package",
            "RemoteSha": "999.0.0",
        }
        for field, value in invalid_values.items():
            invalid = copy.deepcopy(explicit_cran)
            invalid["packages"][package]["description"][field] = value
            expect_rejection(
                lambda candidate=invalid: guard.validate_manifest(
                    candidate, root, check_checksums=True
                ),
                f"invalid provenance value {field}",
            )

        for url in (
            "http://cran.r-project.org",
            "https://cran.r-project.org/path with space",
            "https://cran.r-project.org/path\ncontrol",
        ):
            invalid = copy.deepcopy(explicit_cran)
            invalid["packages"][package]["description"]["RemoteRepos"] = url
            expect_rejection(
                lambda candidate=invalid: guard.validate_manifest(
                    candidate, root, check_checksums=True
                ),
                "an unsafe RemoteRepos URL",
            )

        rogue_fields = (
            "RemoteHost", "RemoteRepo", "GithubRepo", "GitLabRepo",
            "BitbucketRepo", "Remotes", "remotetype",
        )
        for field in rogue_fields:
            for base in (implicit, explicit_cran, explicit_rspm):
                rogue = copy.deepcopy(base)
                rogue["packages"][package]["description"][field] = "attacker-controlled"
                expect_rejection(
                    lambda candidate=rogue: guard.validate_manifest(
                        candidate, root, check_checksums=True
                    ),
                    f"unexpected provenance field {field}",
                )

        core_drift = copy.deepcopy(implicit)
        core_drift["packages"][package]["Source"] = "github"
        expect_rejection(
            lambda: guard.validate_manifest(core_drift, root, check_checksums=True),
            "a non-CRAN package source",
        )
        core_drift = copy.deepcopy(implicit)
        core_drift["packages"][package]["Repository"] = "https://example.invalid/cran"
        expect_rejection(
            lambda: guard.validate_manifest(core_drift, root, check_checksums=True),
            "an untrusted outer repository",
        )
        for value in ("OTHER", "", None, ["CRAN", "RSPM"]):
            core_drift = copy.deepcopy(implicit)
            core_drift["packages"][package]["description"]["Repository"] = value
            expect_rejection(
                lambda candidate=core_drift: guard.validate_manifest(
                    candidate, root, check_checksums=True
                ),
                "an invalid DESCRIPTION repository",
            )
        core_drift = copy.deepcopy(implicit)
        core_drift["packages"][package]["description"]["Package"] = "wrong-package"
        expect_rejection(
            lambda: guard.validate_manifest(core_drift, root, check_checksums=True),
            "a package key/DESCRIPTION mismatch",
        )

        rspm_implicit = copy.deepcopy(implicit)
        rspm_implicit["packages"][package]["description"]["Repository"] = "RSPM"
        expect_rejection(
            lambda: guard.validate_manifest(rspm_implicit, root, check_checksums=True),
            "implicit RSPM provenance",
        )
        rspm_latest = copy.deepcopy(explicit_rspm)
        rspm_latest["packages"][package]["description"]["RemoteRepos"] = (
            "https://packagemanager.posit.co/cran/latest"
        )
        expect_rejection(
            lambda: guard.validate_manifest(rspm_latest, root, check_checksums=True),
            "an unpinned RSPM record",
        )

        stored = copy.deepcopy(manifest)
        first = next(iter(stored["files"]))
        stored["files"][first]["checksum"] = "0" * 32
        manifest_path = root / "manifest.json"
        manifest_path.write_text(
            json.dumps(stored, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        guard.update_manifest(manifest_path, root)
        guard.validate_manifest(
            guard.read_json(manifest_path), root, check_checksums=True
        )
        expect_rejection(
            lambda: guard.update_manifest(root / "not-manifest.json", root),
            "a manifest update outside the fixed checkout-root path",
        )

        drift = copy.deepcopy(manifest)
        first = next(iter(drift["files"]))
        drift["files"][first]["checksum"] = "0" * 32
        expect_rejection(
            lambda: guard.validate_manifest(drift, root, check_checksums=True),
            "a deploy checksum mismatch",
        )

        binary = root / "data/cascade_meta.rds"
        target = root / "binary-symlink-target.rds"
        target.write_bytes(binary.read_bytes())
        binary.unlink()
        try:
            os.symlink(target, binary)
        except (NotImplementedError, OSError):
            shutil.copy2(target, binary)
        else:
            expect_rejection(
                lambda: guard.validate_manifest(manifest, root, check_checksums=False),
                "a symbolic-link deploy entry",
            )


def exercise_receipt_policy() -> None:
    with tempfile.TemporaryDirectory(prefix="cascade-publisher-receipt-") as raw:
        root = Path(raw)
        for relative in guard.ARTIFACT_FILES:
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(relative.encode("ascii"))
        lines = [guard.RECEIPT_SCHEMA, f"base\t{BASE_SHA}"]
        for relative in guard.ARTIFACT_FILES:
            digest = guard.file_digest(root / relative, "sha256")
            lines.append(f"sha256\t{digest}\t{relative}")
        (root / guard.RECEIPT_NAME).write_text(
            "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
        )
        guard.verify_receipt(BASE_SHA, root)

        (root / "unexpected-empty-directory").mkdir()
        expect_rejection(
            lambda: guard.verify_receipt(BASE_SHA, root),
            "an unexpected empty artifact directory",
        )


def exercise_json_and_digest_helpers() -> None:
    with tempfile.TemporaryDirectory(prefix="cascade-publisher-json-") as raw:
        root = Path(raw)
        duplicate = root / "duplicate.json"
        duplicate.write_text('{"version": 1, "version": 1}\n', encoding="utf-8")
        expect_rejection(lambda: guard.read_json(duplicate), "duplicate JSON keys")

        payload = root / "payload.bin"
        payload.write_bytes((b"cascade\x00" * 200_000) + b"end")
        assert guard.file_digest(payload, "sha256") == hashlib.sha256(
            payload.read_bytes()
        ).hexdigest()


def main() -> None:
    exercise_manifest_policy()
    exercise_receipt_policy()
    exercise_json_and_digest_helpers()
    print("TRUSTED PUBLISHER FIXTURES PASSED")


if __name__ == "__main__":
    main()
