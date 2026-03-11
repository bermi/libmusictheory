#!/usr/bin/env python3
"""Audit majmin/scales geometry slot invariants for procedural cutover.

Validates assumptions used by plan 0040:
- regular `scales,*.svg` files contain exactly 324 path slots,
- path slots 0..75 are the geometry layer,
- geometry slot style is stable and linear-path only,
- geometry slot `d` values are invariant across all regular scales files.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import List, Sequence, Tuple
import xml.etree.ElementTree as ET

SCALES_RE = re.compile(r"^scales,(-?\d+),([^,]*),(-?\d+)(?:,(\d+))?\.svg$")
LINEAR_PATH_RE = re.compile(r"^[MLHVZmlhvz0-9eE+.,\-\s]+$")

EXPECTED_REGULAR_FILES = 48
EXPECTED_PATH_SLOTS = 324
EXPECTED_GEOMETRY_SLOTS = 76
EXPECTED_GEOMETRY_STYLE = "fill: #fff; stroke: #666; stroke-width: 1.5; stroke-linejoin: bevel"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        default="tmp/harmoniousapp.net",
        help="Reference root path containing majmin/*.svg (default: tmp/harmoniousapp.net)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON summary",
    )
    return parser.parse_args()


def normalize_style(style: str) -> str:
    return " ".join(style.split())


def parse_scales_name(name: str) -> Tuple[int, str, int, int | None]:
    match = SCALES_RE.match(name)
    if not match:
        raise ValueError(f"invalid scales filename: {name}")
    t_str, family, rotation_str, variant_str = match.groups()
    return int(t_str), family, int(rotation_str), int(variant_str) if variant_str else None


def extract_paths(svg_path: Path) -> List[Tuple[str, str]]:
    tree = ET.parse(svg_path)
    root = tree.getroot()
    out: List[Tuple[str, str]] = []
    for elem in root.iter():
        if elem.tag.rsplit("}", 1)[-1] != "path":
            continue
        style = normalize_style(elem.attrib.get("style", ""))
        d_attr = elem.attrib.get("d", "")
        out.append((style, d_attr))
    return out


def assert_equal(label: str, got: object, expected: object) -> None:
    if got != expected:
        raise AssertionError(f"{label}: got={got!r}, expected={expected!r}")


def audit(majmin_dir: Path) -> dict:
    regular_files: List[Path] = []
    legacy_files = 0

    for path in sorted(majmin_dir.glob("scales,*.svg")):
        t, family, rotation, variant = parse_scales_name(path.name)
        if family == "":
            legacy_files += 1
            if t != -1 or rotation != 0 or variant not in (1, 2):
                raise AssertionError(f"unexpected legacy scales stem: {path.name}")
            continue
        regular_files.append(path)

    assert_equal("regular scales file count", len(regular_files), EXPECTED_REGULAR_FILES)
    assert_equal("legacy scales file count", legacy_files, 2)

    reference_name = regular_files[0].name
    reference_paths = extract_paths(regular_files[0])
    assert_equal(f"{reference_name}: path slot count", len(reference_paths), EXPECTED_PATH_SLOTS)

    reference_geometry = reference_paths[0:EXPECTED_GEOMETRY_SLOTS]

    for slot, (style, d_attr) in enumerate(reference_geometry):
        assert_equal(f"{reference_name}: geometry style slot {slot}", style, EXPECTED_GEOMETRY_STYLE)
        if not LINEAR_PATH_RE.fullmatch(d_attr):
            raise AssertionError(f"{reference_name}: slot {slot} geometry d is not linear path")

    for path in regular_files[1:]:
        rows = extract_paths(path)
        assert_equal(f"{path.name}: path slot count", len(rows), EXPECTED_PATH_SLOTS)

        for slot in range(EXPECTED_GEOMETRY_SLOTS):
            style, d_attr = rows[slot]
            ref_style, ref_d = reference_geometry[slot]
            assert_equal(f"{path.name}: geometry style slot {slot}", style, ref_style)
            assert_equal(f"{path.name}: geometry d slot {slot}", d_attr, ref_d)

    return {
        "majmin_dir": str(majmin_dir),
        "regular_files": len(regular_files),
        "legacy_files": legacy_files,
        "path_slots": EXPECTED_PATH_SLOTS,
        "geometry_slots": EXPECTED_GEOMETRY_SLOTS,
        "geometry_style": EXPECTED_GEOMETRY_STYLE,
        "reference_file": reference_name,
    }


def main() -> None:
    args = parse_args()
    root = Path(args.root)
    majmin_dir = root / "majmin"
    if not majmin_dir.is_dir():
        raise FileNotFoundError(f"missing majmin directory: {majmin_dir}")

    summary = audit(majmin_dir)
    if args.json:
        print(json.dumps(summary, sort_keys=True, indent=2))
    else:
        print(
            "majmin scales geometry slots:"
            f" files={summary['regular_files']}"
            f" slots={summary['path_slots']}"
            f" geometry_slots={summary['geometry_slots']}"
        )


if __name__ == "__main__":
    main()
