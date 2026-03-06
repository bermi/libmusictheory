#!/usr/bin/env python3
"""Audit majmin polygon-geometry template invariants.

This script verifies that the large tile polygon layer is structurally invariant
within the expected scene groups:

- modes: grouped by (family, rotation) across all transpositions
- scales: grouped by family across all transpositions

It is a migration guardrail for replacing packed majmin reconstruction with
scene-driven algorithmic geometry generation.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple
import xml.etree.ElementTree as ET

MODES_RE = re.compile(r"^modes,(-?\d+),([^,]*),(-?\d+)(?:,(\d+))?\.svg$")
SCALES_RE = re.compile(r"^scales,(-?\d+),([^,]*),(-?\d+)(?:,(\d+))?\.svg$")
LINEAR_PATH_RE = re.compile(r"^[MLHVZmlhvz0-9eE+.,\-\s]+$")

MODES_EXPECTED_TRANSPOSITIONS = {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
SCALES_EXPECTED_TRANSPOSITIONS = set(range(12))
EXPECTED_FAMILIES = ("dntri", "hex", "rhomb", "uptri")


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
        help="Emit JSON summary instead of a short text summary",
    )
    return parser.parse_args()


def normalize_style(style: str) -> str:
    return " ".join(style.split())


def is_polygon_geometry_path(d_attr: str, style: str) -> bool:
    if "stroke-width: 1.5" not in style:
        return False
    if "stroke-linejoin: bevel" not in style:
        return False
    return bool(LINEAR_PATH_RE.fullmatch(d_attr))


def extract_geometry_signature(svg_path: Path) -> List[Tuple[str, str]]:
    tree = ET.parse(svg_path)
    root = tree.getroot()
    signature: List[Tuple[str, str]] = []
    for elem in root.iter():
        tag = elem.tag.rsplit("}", 1)[-1]
        if tag != "path":
            continue
        d_attr = elem.attrib.get("d", "")
        style = elem.attrib.get("style", "")
        if is_polygon_geometry_path(d_attr, style):
            signature.append((d_attr, normalize_style(style)))
    return signature


def parse_modes_name(name: str) -> Tuple[int, str, int, int | None]:
    match = MODES_RE.match(name)
    if not match:
        raise ValueError(f"invalid modes filename: {name}")
    t_str, family, rotation_str, variant_str = match.groups()
    return int(t_str), family, int(rotation_str), int(variant_str) if variant_str else None


def parse_scales_name(name: str) -> Tuple[int, str, int, int | None]:
    match = SCALES_RE.match(name)
    if not match:
        raise ValueError(f"invalid scales filename: {name}")
    t_str, family, rotation_str, variant_str = match.groups()
    return int(t_str), family, int(rotation_str), int(variant_str) if variant_str else None


def assert_transposition_set(
    got: Iterable[int],
    expected: Sequence[int] | set[int],
    label: str,
) -> None:
    got_set = set(got)
    expected_set = set(expected)
    if got_set != expected_set:
        raise AssertionError(f"{label}: transposition set mismatch: got={sorted(got_set)} expected={sorted(expected_set)}")


def audit_modes(majmin_dir: Path) -> Dict[str, object]:
    groups: Dict[Tuple[str, int], List[Tuple[int, str, List[Tuple[str, str]]]]] = defaultdict(list)
    legacy_count = 0

    for path in sorted(majmin_dir.glob("modes,*.svg")):
        t, family, rotation, variant = parse_modes_name(path.name)
        if family == "":
            legacy_count += 1
            if t != -1 or rotation != -3 or variant not in (1, 2):
                raise AssertionError(f"unexpected legacy modes stem: {path.name}")
            continue
        sig = extract_geometry_signature(path)
        groups[(family, rotation)].append((t, path.name, sig))

    if legacy_count != 2:
        raise AssertionError(f"expected 2 legacy modes files, got {legacy_count}")

    summary_groups = {}
    for (family, rotation), rows in sorted(groups.items()):
        if family not in EXPECTED_FAMILIES:
            raise AssertionError(f"unexpected modes family: {family}")
        if not rows:
            raise AssertionError(f"empty modes group: {(family, rotation)}")

        assert_transposition_set((row[0] for row in rows), MODES_EXPECTED_TRANSPOSITIONS, f"modes group {(family, rotation)}")
        ref_name = rows[0][1]
        ref_sig = rows[0][2]
        if len(ref_sig) == 0:
            raise AssertionError(f"modes group {(family, rotation)} has zero geometry paths")
        for t, name, sig in rows[1:]:
            if sig != ref_sig:
                raise AssertionError(
                    f"modes geometry mismatch for group {(family, rotation)} between {ref_name} and {name} (t={t})"
                )
        summary_groups[f"{family}:{rotation}"] = {
            "count": len(rows),
            "geometry_path_count": len(ref_sig),
        }

    if len(groups) != 28:
        raise AssertionError(f"expected 28 regular modes geometry groups, got {len(groups)}")

    return {
        "legacy_count": legacy_count,
        "group_count": len(groups),
        "groups": summary_groups,
    }


def audit_scales(majmin_dir: Path) -> Dict[str, object]:
    groups: Dict[str, List[Tuple[int, str, List[Tuple[str, str]]]]] = defaultdict(list)
    legacy_count = 0

    for path in sorted(majmin_dir.glob("scales,*.svg")):
        t, family, rotation, variant = parse_scales_name(path.name)
        if family == "":
            legacy_count += 1
            if t != -1 or rotation != 0 or variant not in (1, 2):
                raise AssertionError(f"unexpected legacy scales stem: {path.name}")
            continue
        sig = extract_geometry_signature(path)
        groups[family].append((t, path.name, sig))

    if legacy_count != 2:
        raise AssertionError(f"expected 2 legacy scales files, got {legacy_count}")

    summary_groups = {}
    for family in EXPECTED_FAMILIES:
        rows = groups.get(family, [])
        if not rows:
            raise AssertionError(f"missing scales family group: {family}")
        assert_transposition_set((row[0] for row in rows), SCALES_EXPECTED_TRANSPOSITIONS, f"scales family {family}")
        ref_name = rows[0][1]
        ref_sig = rows[0][2]
        if len(ref_sig) == 0:
            raise AssertionError(f"scales family {family} has zero geometry paths")
        for t, name, sig in rows[1:]:
            if sig != ref_sig:
                raise AssertionError(f"scales geometry mismatch for family {family} between {ref_name} and {name} (t={t})")
        summary_groups[family] = {
            "count": len(rows),
            "geometry_path_count": len(ref_sig),
        }

    extra_families = sorted(set(groups.keys()) - set(EXPECTED_FAMILIES))
    if extra_families:
        raise AssertionError(f"unexpected scales families: {extra_families}")

    return {
        "legacy_count": legacy_count,
        "group_count": len(summary_groups),
        "groups": summary_groups,
    }


def main() -> None:
    args = parse_args()
    root = Path(args.root)
    majmin_dir = root / "majmin"
    if not majmin_dir.is_dir():
        raise FileNotFoundError(f"missing majmin directory: {majmin_dir}")

    summary = {
        "majmin_dir": str(majmin_dir),
        "modes": audit_modes(majmin_dir),
        "scales": audit_scales(majmin_dir),
    }

    if args.json:
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print(
            "majmin geometry invariant groups:"
            f" modes={summary['modes']['group_count']}"
            f" scales={summary['scales']['group_count']}"
        )


if __name__ == "__main__":
    main()
