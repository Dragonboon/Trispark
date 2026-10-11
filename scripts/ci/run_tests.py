#!/usr/bin/env python3
"""Run Godot import and headless match-3 regressions; fail on script errors or timeout."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
ERROR = re.compile(r"(?:SCRIPT ERROR:|Parse Error:|Failed to load script|^ERROR:|Assertion failed)", re.MULTILINE)


def run(command: list[str], timeout: int, require_pass: bool = False, pass_marker: str = "") -> bool:
    print("$ " + " ".join(command), flush=True)
    try:
        process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                 errors="replace", timeout=timeout, check=False)
    except (subprocess.TimeoutExpired, FileNotFoundError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr, flush=True)
        return False
    output = process.stdout + "\n" + process.stderr
    print(output, flush=True)
    ok = process.returncode == 0 and not ERROR.search(output)
    if require_pass:
        ok = ok and pass_marker in output
    return bool(ok)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--timeout", type=int, default=60)
    args = parser.parse_args()
    root = str(ROOT)
    if not run([args.godot, "--headless", "--path", root, "--editor", "--quit"], args.timeout):
        return 1
    for script, marker in [("test_diagonals.gd", "Match3 diagonal/gravity regression: PASS"),
                           ("test_movement_api.gd", "Match3 movement API regression: PASS")]:
        if not run([args.godot, "--headless", "--path", root, "--script",
                    "res://tests/" + script], args.timeout, require_pass=True, pass_marker=marker):
            return 1
    print("RESULT: PASS", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
