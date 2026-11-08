#!/usr/bin/env python3
"""Verify a Lorong Sunyi Android APK's API levels, ABI set, and bundled game data."""

from __future__ import annotations

import os
import subprocess
import sys
import zipfile
from pathlib import Path

MIN_SDK_REQUIRED = 30
EXPECTED_TARGET_SDK = 35
EXPECTED_ABIS = {"arm64-v8a"}
REQUIRED_MARKERS = (
    "mika-fox-runtime-384x576",
    "desa-kampung-runtime-1280x720",
    "scripts/lorong/room.gdc",
    "scripts/lorong/game_controller.gdc",
)


def fail(message: str) -> "NoReturn":
    print(f"[android-apk] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def run_text(command: list[str]) -> str:
    try:
        result = subprocess.run(command, check=True, text=True, capture_output=True)
    except FileNotFoundError as exc:
        fail(f"tool tidak ditemukan: {exc.filename}")
    except subprocess.CalledProcessError as exc:
        fail(f"perintah gagal ({' '.join(command)}): {exc.stderr.strip()}")
    return result.stdout.strip()


def main() -> int:
    if len(sys.argv) != 2:
        fail("usage: verify_android_apk.py <apk-path>")

    apk = Path(sys.argv[1]).resolve()
    if not apk.is_file() or apk.stat().st_size == 0:
        fail(f"APK tidak ada atau kosong: {apk}")

    sdk_root = Path(
        os.environ.get("ANDROID_SDK_ROOT")
        or os.environ.get("ANDROID_HOME")
        or str(Path.home() / "Android" / "Sdk")
    )
    analyzer = sdk_root / "cmdline-tools" / "latest" / "bin" / "apkanalyzer"
    if not analyzer.is_file():
        fail(f"apkanalyzer tidak ditemukan di {analyzer}")

    min_sdk_text = run_text([str(analyzer), "manifest", "min-sdk", str(apk)])
    target_sdk_text = run_text([str(analyzer), "manifest", "target-sdk", str(apk)])
    try:
        min_sdk = int(min_sdk_text)
        target_sdk = int(target_sdk_text)
    except ValueError:
        fail(f"nilai API tidak numerik: min={min_sdk_text!r}, target={target_sdk_text!r}")

    if min_sdk < MIN_SDK_REQUIRED:
        fail(f"minSdk={min_sdk}; harus >= {MIN_SDK_REQUIRED}")
    if target_sdk != EXPECTED_TARGET_SDK:
        fail(f"targetSdk={target_sdk}; harus {EXPECTED_TARGET_SDK}")

    try:
        with zipfile.ZipFile(apk) as archive:
            names = archive.namelist()
    except zipfile.BadZipFile as exc:
        fail(f"APK bukan arsip ZIP yang valid: {exc}")

    native_abis = {
        name.split("/")[1]
        for name in names
        if name.startswith("lib/") and len(name.split("/")) >= 3
    }
    if native_abis != EXPECTED_ABIS:
        fail(f"ABI native ditemukan {sorted(native_abis)}; yang diizinkan hanya {sorted(EXPECTED_ABIS)}")

    missing = [marker for marker in REQUIRED_MARKERS if not any(marker in name for name in names)]
    if missing:
        fail("aset/skrip runtime tidak ditemukan di APK: " + ", ".join(missing))

    print(
        "[android-apk] PASS: "
        f"minSdk={min_sdk} (required >= {MIN_SDK_REQUIRED}), "
        f"targetSdk={target_sdk} (expected {EXPECTED_TARGET_SDK}), ABI={','.join(sorted(native_abis))}; "
        "background, Mika fox, room, dan controller ada di APK."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
