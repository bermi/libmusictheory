#!/usr/bin/env python3
"""Audit majmin scale template invariants for algorithmic migration.

Verifies:
  - regular scale files form 4 families x 12 transpositions,
  - each family has a single masked template when href/style/d are masked,
  - regular scales satisfy rotation = (7 * transposition) mod 12,
  - two legacy overview files remain present.
"""

from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path
from typing import Dict, Tuple


EXPECTED_FAMILIES = ("dntri", "hex", "rhomb", "uptri")
EXPECTED_TRANS = tuple(str(i) for i in range(12))
EXPECTED_LEGACY = {"scales,-1,,0,1", "scales,-1,,0,2"}
EXPECTED_TOTAL = 50
EXPECTED_REGULAR = 48

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


def mask_template(svg_text: str) -> str:
    out = HREF_RE.sub('href="@"', svg_text)
    out = STYLE_RE.sub('style="@"', out)
    out = D_RE.sub('d="@"', out)
    return out


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    majmin_dir = root / "majmin"
    if not majmin_dir.is_dir():
        raise FileNotFoundError(f"missing majmin directory: {majmin_dir}")

    files = sorted(majmin_dir.glob("scales,*.svg"))
    assert_equal("scales file count", len(files), EXPECTED_TOTAL)

    legacy_seen: set[str] = set()
    groups: Dict[str, list[Tuple[str, str, str, str]]] = collections.defaultdict(list)

    for svg_path in files:
        stem = svg_path.stem
        parts = stem.split(",")
        if len(parts) == 5:
            kind, trans, family, rotation, variant = parts
            if kind != "scales" or trans != "-1" or family != "" or rotation != "0" or variant not in {"1", "2"}:
                raise AssertionError(f"{stem}: invalid legacy scale stem")
            legacy_seen.add(stem)
            continue

        if len(parts) != 4:
            raise AssertionError(f"{stem}: invalid regular scale stem token count ({len(parts)})")

        kind, trans, family, rotation = parts
        if kind != "scales":
            raise AssertionError(f"{stem}: expected scales kind token")
        if family not in EXPECTED_FAMILIES:
            raise AssertionError(f"{stem}: unexpected family token {family!r}")
        if trans not in EXPECTED_TRANS:
            raise AssertionError(f"{stem}: unexpected transposition token {trans!r}")
        if rotation not in EXPECTED_TRANS:
            raise AssertionError(f"{stem}: unexpected rotation token {rotation!r}")

        trans_int = int(trans)
        rotation_int = int(rotation)
        if (7 * trans_int) % 12 != rotation_int:
            raise AssertionError(f"{stem}: rotation formula mismatch expected {(7 * trans_int) % 12}")

        masked = mask_template(svg_path.read_text(encoding="utf-8"))
        groups[family].append((stem, trans, rotation, masked))

    assert_equal("legacy scale set", legacy_seen, EXPECTED_LEGACY)

    regular_count = sum(len(v) for v in groups.values())
    assert_equal("regular scale count", regular_count, EXPECTED_REGULAR)

    family_reports = []
    for family in EXPECTED_FAMILIES:
        entries = groups.get(family, [])
        assert_equal(f"{family} entry count", len(entries), 12)
        trans_seen = sorted({e[1] for e in entries}, key=int)
        rotation_seen = sorted({e[2] for e in entries}, key=int)
        assert_equal(f"{family} transposition domain", trans_seen, list(EXPECTED_TRANS))
        assert_equal(f"{family} rotation domain", rotation_seen, list(EXPECTED_TRANS))
        masked_count = len({e[3] for e in entries})
        assert_equal(f"{family} masked template count", masked_count, 1)

        family_reports.append(
            {
                "family": family,
                "count": len(entries),
                "masked_templates": masked_count,
                "sample": entries[0][0],
            }
        )

    report = {
        "root": str(root),
        "scales_files": len(files),
        "regular_files": regular_count,
        "legacy_files": sorted(legacy_seen),
        "families": family_reports,
    }

    if args.json:
        print(json.dumps(report, separators=(",", ":"), sort_keys=True))
    else:
        print(json.dumps(report, indent=2, sort_keys=True))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
