#!/usr/bin/env python3
"""Audit harmonious vertical-text compatibility primitive invariants.

This script validates that:
1. `vert-text-black` and `vert-text-b2t-black` SVG labels are composed from a
   stable, finite primitive set.
2. Primitive frequencies and per-stem segmentation are deterministic under a
   character-level decomposition model.

The audit is a migration guardrail before replacing per-stem path tables with
algorithmic glyph composition.
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import re
import sys
from dataclasses import dataclass


EXPECTED_FILE_COUNTS = {
    "vert-text-black": 115,
    "vert-text-b2t-black": 115,
}

# Number of path sub-primitives expected per symbol.
EXPECTED_PRIMITIVE_COUNTS = {
    "-": 1,
    "0": 2,
    "1": 1,
    "2": 1,
    "3": 1,
    "4": 1,
    "5": 1,
    "6": 2,
    "7": 1,
    "8": 3,
    "9": 2,
    "Z": 1,
}

PATH_D_RE = re.compile(r'<path[^>]* d="([^"]+)"')
SUBPATH_RE = re.compile(r"M([+-]?\d*\.?\d+),?([+-]?\d*\.?\d+)([^M]*)")


@dataclass(frozen=True)
class SubPath:
    x: float
    y: float
    body: str


@dataclass(frozen=True)
class Record:
    kind: str
    stem: str
    subpaths: tuple[SubPath, ...]


def fail(msg: str) -> None:
    print(f"[text-compat-audit] FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default="tmp/harmoniousapp.net", help="harmoniousapp root")
    return parser.parse_args()


def parse_record(kind: str, svg_path: pathlib.Path) -> Record:
    text = svg_path.read_text(encoding="utf-8")
    match = PATH_D_RE.search(text)
    if not match:
        fail(f"{svg_path}: missing path d attribute")
    d = match.group(1)
    subpaths = []
    for m in SUBPATH_RE.finditer(d):
        subpaths.append(SubPath(float(m.group(1)), float(m.group(2)), m.group(3)))
    if not subpaths:
        fail(f"{svg_path}: no subpaths parsed")
    return Record(kind=kind, stem=svg_path.stem, subpaths=tuple(subpaths))


def collect_records(root: pathlib.Path) -> list[Record]:
    out: list[Record] = []
    for kind, expected in EXPECTED_FILE_COUNTS.items():
        d = root / kind
        if not d.is_dir():
            fail(f"missing directory: {d}")
        files = sorted(d.glob("*.svg"))
        if len(files) != expected:
            fail(f"{kind}: expected {expected} files, found {len(files)}")
        for svg_path in files:
            out.append(parse_record(kind, svg_path))
    return out


def assign_bodies(records: list[Record]) -> tuple[dict[str, int], dict[int, str], dict[str, list[int]]]:
    body_to_id: dict[str, int] = {}
    body_freq: collections.Counter[int] = collections.Counter()
    char_freq: collections.Counter[str] = collections.Counter()

    for rec in records:
        for ch in rec.stem:
            if ch not in EXPECTED_PRIMITIVE_COUNTS:
                fail(f"{rec.kind}/{rec.stem}: unexpected character '{ch}'")
            char_freq[ch] += 1
        for sub in rec.subpaths:
            if sub.body not in body_to_id:
                body_to_id[sub.body] = len(body_to_id)
            body_freq[body_to_id[sub.body]] += 1

    if set(char_freq.keys()) != set(EXPECTED_PRIMITIVE_COUNTS.keys()):
        fail(
            "character alphabet mismatch: "
            f"expected={sorted(EXPECTED_PRIMITIVE_COUNTS.keys())} "
            f"actual={sorted(char_freq.keys())}"
        )

    expected_total_primitives = sum(EXPECTED_PRIMITIVE_COUNTS.values())
    if len(body_to_id) != expected_total_primitives:
        fail(
            f"primitive body count mismatch: expected {expected_total_primitives}, "
            f"found {len(body_to_id)}"
        )

    # Candidate body IDs per symbol from frequency matching.
    candidates: dict[str, list[int]] = {}
    for ch, freq in sorted(char_freq.items()):
        candidates[ch] = sorted(bid for bid, body_count in body_freq.items() if body_count == freq)

    assigned: dict[str, list[int]] = {}

    # First pass: unique frequency-mapped symbols.
    for ch, body_ids in candidates.items():
        expected_parts = EXPECTED_PRIMITIVE_COUNTS[ch]
        if len(body_ids) == expected_parts and (expected_parts > 1 or len(body_ids) == 1):
            # Keep ambiguous singletons (notably 4/5) for disambiguation pass.
            if expected_parts == 1 and len(body_ids) > 1:
                continue
            assigned[ch] = body_ids

    # Disambiguate 4/5 via known b2t stems.
    rec_by_key = {(r.kind, r.stem): r for r in records}
    for stem, ch in (("4-1", "4"), ("5-1", "5")):
        rec = rec_by_key.get(("vert-text-b2t-black", stem))
        if rec is None:
            fail(f"missing disambiguation stem vert-text-b2t-black/{stem}.svg")
        ids = [body_to_id[sub.body] for sub in rec.subpaths]
        if len(ids) < 3:
            fail(f"disambiguation stem {stem} has too few subpaths ({len(ids)})")
        assigned[ch] = [ids[0]]

    # Verify all symbols assigned with expected primitive count.
    for ch, expected_parts in EXPECTED_PRIMITIVE_COUNTS.items():
        body_ids = assigned.get(ch)
        if body_ids is None:
            fail(f"no body assignment for symbol '{ch}'")
        if len(body_ids) != expected_parts:
            fail(
                f"symbol '{ch}' primitive-count mismatch: expected {expected_parts}, "
                f"assigned {len(body_ids)}"
            )

    # Invert map for diagnostics.
    body_to_symbol: dict[int, str] = {}
    for ch, body_ids in assigned.items():
        for bid in body_ids:
            if bid in body_to_symbol and body_to_symbol[bid] != ch:
                fail(f"body {bid} assigned to multiple symbols: {body_to_symbol[bid]}, {ch}")
            body_to_symbol[bid] = ch

    if len(body_to_symbol) != len(body_to_id):
        fail(
            f"body coverage mismatch: assigned {len(body_to_symbol)} / "
            f"{len(body_to_id)} primitive bodies"
        )

    return body_to_id, body_to_symbol, assigned


def infer_ordered_symbol_sequences(records: list[Record], body_to_id: dict[str, int], assigned: dict[str, list[int]]) -> dict[str, list[int]]:
    ordered: dict[str, list[int]] = {}

    # Single-part symbols are direct.
    for ch, part_count in EXPECTED_PRIMITIVE_COUNTS.items():
        if part_count == 1:
            ordered[ch] = assigned[ch]

    # Multi-part symbols that appear as first character can be inferred from prefix.
    for ch in ("6", "8", "9"):
        rec = next((r for r in records if r.stem.startswith(f"{ch}-")), None)
        if rec is None:
            fail(f"missing prefix inference stem for symbol '{ch}'")
        ids = [body_to_id[sub.body] for sub in rec.subpaths]
        k = EXPECTED_PRIMITIVE_COUNTS[ch]
        ordered[ch] = ids[:k]

    # `0` never appears first in these stems; infer from `*-10`.
    rec = next((r for r in records if r.stem.endswith("-10")), None)
    if rec is None:
        fail("missing '*-10' stem to infer symbol '0' ordering")
    ids = [body_to_id[sub.body] for sub in rec.subpaths]
    first_char = rec.stem[0]
    start = (
        EXPECTED_PRIMITIVE_COUNTS[first_char]
        + EXPECTED_PRIMITIVE_COUNTS["-"]
        + EXPECTED_PRIMITIVE_COUNTS["1"]
    )
    ordered["0"] = ids[start : start + EXPECTED_PRIMITIVE_COUNTS["0"]]

    # Sanity: ordered sets match assigned sets.
    for ch, seq in ordered.items():
        if sorted(seq) != sorted(assigned[ch]):
            fail(f"ordered primitive sequence mismatch for '{ch}'")
        if len(seq) != EXPECTED_PRIMITIVE_COUNTS[ch]:
            fail(f"ordered primitive count mismatch for '{ch}'")

    return ordered


def validate_segmentation(records: list[Record], body_to_id: dict[str, int], ordered: dict[str, list[int]]) -> None:
    for rec in records:
        ids = [body_to_id[sub.body] for sub in rec.subpaths]
        cursor = 0
        for ch in rec.stem:
            expected = ordered[ch]
            n = len(expected)
            actual = ids[cursor : cursor + n]
            if actual != expected:
                fail(
                    f"{rec.kind}/{rec.stem}: segmentation mismatch for symbol '{ch}' "
                    f"at index {cursor}: expected {expected}, got {actual}"
                )
            cursor += n
        if cursor != len(ids):
            fail(
                f"{rec.kind}/{rec.stem}: segmentation consumed {cursor} subpaths, "
                f"found {len(ids)}"
            )


def main() -> int:
    args = parse_args()
    root = pathlib.Path(args.root)

    records = collect_records(root)
    body_to_id, _body_to_symbol, assigned = assign_bodies(records)
    ordered = infer_ordered_symbol_sequences(records, body_to_id, assigned)
    validate_segmentation(records, body_to_id, ordered)

    print("[text-compat-audit] PASS")
    print(f"[text-compat-audit] files: {len(records)}")
    print(f"[text-compat-audit] primitive_bodies: {len(body_to_id)}")
    print(
        "[text-compat-audit] primitive_parts_per_symbol: "
        + ", ".join(f"{k}:{EXPECTED_PRIMITIVE_COUNTS[k]}" for k in sorted(EXPECTED_PRIMITIVE_COUNTS))
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
