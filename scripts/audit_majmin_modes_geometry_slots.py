#!/usr/bin/env python3
"""Audit majmin/modes geometry-slot prefix invariants.

Validates assumptions used by plan 0045:
- regular modes files are grouped by (family, rotation),
- geometry paths are a contiguous prefix [0..N) in each group,
- geometry style and `d` payload are invariant across transpositions per group.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple
import xml.etree.ElementTree as ET

MODES_RE = re.compile(r"^modes,(-?\d+),([^,]*),(-?\d+)(?:,(\d+))?\.svg$")
LINEAR_PATH_RE = re.compile(r"^[MLHVZmlhvz0-9eE+.,\-\s]+$")

EXPECTED_REGULAR_GROUPS = 28
EXPECTED_LEGACY_FILES = 2
EXPECTED_TRANSPOSITIONS = {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}


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


def parse_modes_name(name: str) -> Tuple[int, str, int, int | None]:
    match = MODES_RE.match(name)
    if not match:
        raise ValueError(f"invalid modes filename: {name}")
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


def is_geometry_slot(style: str, d_attr: str) -> bool:
    if "stroke-width: 1.5" not in style:
        return False
    if "stroke-linejoin: bevel" not in style:
        return False
    return bool(LINEAR_PATH_RE.fullmatch(d_attr))


def assert_equal(label: str, got: object, expected: object) -> None:
    if got != expected:
        raise AssertionError(f"{label}: got={got!r}, expected={expected!r}")


def geometry_prefix(rows: List[Tuple[str, str]], stem: str) -> List[Tuple[str, str]]:
    prefix: List[Tuple[str, str]] = []
    seen_non_geometry = False
    for slot, (style, d_attr) in enumerate(rows):
        geom = is_geometry_slot(style, d_attr)
        if geom and seen_non_geometry:
            raise AssertionError(f"{stem}: non-prefix geometry slot at index {slot}")
        if geom:
            prefix.append((style, d_attr))
        else:
            seen_non_geometry = True
    if len(prefix) == 0:
        raise AssertionError(f"{stem}: zero geometry prefix slots")
    return prefix


def audit(majmin_dir: Path) -> dict:
    groups: Dict[Tuple[str, int], List[Tuple[int, str, List[Tuple[str, str]]]]] = defaultdict(list)
    legacy_count = 0

    for path in sorted(majmin_dir.glob("modes,*.svg")):
        t, family, rotation, variant = parse_modes_name(path.name)
        if family == "":
            legacy_count += 1
            if t != -1 or rotation != -3 or variant not in (1, 2):
                raise AssertionError(f"unexpected legacy modes stem: {path.name}")
            continue
        rows = extract_paths(path)
        prefix = geometry_prefix(rows, path.name)
        groups[(family, rotation)].append((t, path.name, prefix))

    assert_equal("legacy modes file count", legacy_count, EXPECTED_LEGACY_FILES)
    assert_equal("regular mode group count", len(groups), EXPECTED_REGULAR_GROUPS)

    summary_groups = {}
    for (family, rotation), entries in sorted(groups.items()):
        transpositions = {row[0] for row in entries}
        assert_equal(f"{family}/{rotation} transposition domain", transpositions, EXPECTED_TRANSPOSITIONS)

        reference_name = entries[0][1]
        reference_prefix = entries[0][2]
        for t, name, prefix in entries[1:]:
            if prefix != reference_prefix:
                raise AssertionError(
                    f"{family}/{rotation}: geometry prefix mismatch between {reference_name} and {name} (t={t})"
                )

        summary_groups[f"{family}:{rotation}"] = {
            "file_count": len(entries),
            "geometry_prefix_slots": len(reference_prefix),
        }

    return {
        "majmin_dir": str(majmin_dir),
        "legacy_files": legacy_count,
        "group_count": len(groups),
        "groups": summary_groups,
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
            "majmin modes geometry slots:"
            f" groups={summary['group_count']}"
            f" legacy={summary['legacy_files']}"
        )


if __name__ == "__main__":
    main()
