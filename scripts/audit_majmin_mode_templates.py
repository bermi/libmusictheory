#!/usr/bin/env python3
"""Audit majmin mode template invariants for algorithmic migration.

Verifies that for each (family, rotation) group in majmin/modes:
  - exactly 13 transpositions exist,
  - non-template structure is invariant when masking href/style/d payloads.
"""

from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path
from typing import Dict, Optional, Tuple


EXPECTED_GROUPS = 28
EXPECTED_TRANSPOSITIONS = {"-1", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"}
EXPECTED_FAMILIES = {"dntri", "hex", "rhomb", "uptri"}
EXPECTED_ROTATIONS_BY_FAMILY = {
    "dntri": {"0", "1", "3", "4", "7", "10", "11"},
    "hex": {"0", "1", "7", "8", "9", "10", "11"},
    "rhomb": {"0", "1", "3", "7", "9", "10", "11"},
    "uptri": {"0", "1", "4", "7", "8", "10", "11"},
}

HREF_RE = re.compile(r'href="[^"]*"')
STYLE_RE = re.compile(r'style="[^"]*"')
D_RE = re.compile(r'd="[^"]*"')


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
        help="Print compact JSON only.",
    )
    return parser.parse_args()


def assert_equal(label: str, got, expected) -> None:
    if got != expected:
        raise AssertionError(f"{label}: expected {expected}, got {got}")


def parse_mode_stem(stem: str) -> Optional[Tuple[str, str, str, str]]:
    parts = stem.split(",")
    if len(parts) == 5:
        # Legacy overview variants are intentionally outside grouped template audit.
        kind, transposition, family, _rotation, _variant = parts
        if kind == "modes" and transposition == "-1" and family == "":
            return None
        raise AssertionError(f"{stem}: unexpected 5-token mode stem shape")
    if len(parts) != 4:
        raise AssertionError(f"{stem}: expected 4 tokens for mode template audit")
    kind, transposition, family, rotation = parts
    if kind != "modes":
        raise AssertionError(f"{stem}: expected modes kind token")
    if family not in EXPECTED_FAMILIES:
        raise AssertionError(f"{stem}: unexpected family token {family!r}")
    return kind, transposition, family, rotation


def mask_template(svg_text: str) -> str:
    masked = HREF_RE.sub('href="@"', svg_text)
    masked = STYLE_RE.sub('style="@"', masked)
    masked = D_RE.sub('d="@"', masked)
    return masked


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    majmin_dir = root / "majmin"
    if not majmin_dir.is_dir():
        raise FileNotFoundError(f"missing majmin directory: {majmin_dir}")

    mode_files = sorted(majmin_dir.glob("modes,*.svg"))
    groups: Dict[Tuple[str, str], list[tuple[str, str, str]]] = collections.defaultdict(list)

    for svg_path in mode_files:
        stem = svg_path.stem
        parsed = parse_mode_stem(stem)
        if parsed is None:
            continue
        _kind, transposition, family, rotation = parsed
        masked = mask_template(svg_path.read_text(encoding="utf-8"))
        groups[(family, rotation)].append((stem, transposition, masked))

    assert_equal("mode template group count", len(groups), EXPECTED_GROUPS)

    report_groups = []

    by_family_rotations: Dict[str, set[str]] = collections.defaultdict(set)
    for (family, rotation), entries in sorted(groups.items()):
        by_family_rotations[family].add(rotation)

        transpositions = {entry[1] for entry in entries}
        assert_equal(f"{family}/{rotation} transposition count", len(entries), 13)
        assert_equal(f"{family}/{rotation} transposition domain", transpositions, EXPECTED_TRANSPOSITIONS)

        masked_templates = {entry[2] for entry in entries}
        assert_equal(f"{family}/{rotation} masked-structure invariance", len(masked_templates), 1)

        report_groups.append(
            {
                "family": family,
                "rotation": int(rotation),
                "count": len(entries),
                "sample": entries[0][0],
            }
        )

    for family in sorted(EXPECTED_FAMILIES):
        assert_equal(
            f"{family} rotation domain",
            by_family_rotations.get(family, set()),
            EXPECTED_ROTATIONS_BY_FAMILY[family],
        )

    report = {
        "root": str(root),
        "mode_files": len(mode_files),
        "template_groups": len(groups),
        "groups": report_groups,
        "expected": {
            "groups": EXPECTED_GROUPS,
            "transpositions": sorted(EXPECTED_TRANSPOSITIONS, key=lambda s: int(s)),
            "families": sorted(EXPECTED_FAMILIES),
            "rotations_by_family": {k: sorted(v, key=lambda s: int(s)) for k, v in EXPECTED_ROTATIONS_BY_FAMILY.items()},
        },
    }

    if args.json:
        print(json.dumps(report, separators=(",", ":"), sort_keys=True))
    else:
        print(json.dumps(report, indent=2, sort_keys=True))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
