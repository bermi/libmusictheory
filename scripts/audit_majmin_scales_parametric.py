#!/usr/bin/env python3
"""Audit majmin/scales parametric decomposition invariants.

This guardrail captures the structural model needed to replace packed majmin
compatibility replay with scene-driven rendering:

- regular scales are 4 families x 12 transpositions,
- each family has one structural skeleton,
- href/style/path slots split into static vs transposition-variant classes,
- cross-family diffs for a fixed transposition are isolated to one path slot.
"""

from __future__ import annotations

import argparse
import collections
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple


EXPECTED_FAMILIES: Sequence[str] = ("dntri", "hex", "rhomb", "uptri")
EXPECTED_TRANS: Sequence[int] = tuple(range(12))
EXPECTED_REGULAR_FILES = 48
EXPECTED_HREF_SLOTS = 153
EXPECTED_STYLE_SLOTS = 324
EXPECTED_PATH_SLOTS = 324
EXPECTED_STYLE_DYNAMIC = 58
EXPECTED_STYLE_STATIC = 266
EXPECTED_PATH_DYNAMIC = 95
EXPECTED_PATH_STATIC = 229
EXPECTED_CROSS_FAMILY_SHARED_PATH_SLOTS = 323

TAG_RE = re.compile(r"<(/?)([a-zA-Z]+)([^>]*)>")
ATTR_RE = re.compile(r'([a-zA-Z_:][\w:.-]*)="([^"]*)"')
NUM_RE = re.compile(r"[+-]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?")

MARKER_HREF = "\x1d"
MARKER_STYLE = "\x1e"
MARKER_D = "\x1f"
MARKER_NUM = "\x01"
SCALE = 10**17

ARG_FLAGS = {
    "M": ["x", "y"],
    "L": ["x", "y"],
    "T": ["x", "y"],
    "H": ["x"],
    "V": ["y"],
    "S": ["x", "y", "x", "y"],
    "Q": ["x", "y", "x", "y"],
    "C": ["x", "y", "x", "y", "x", "y"],
    "A": ["n", "n", "n", "n", "n", "x", "y"],
    "m": ["x", "y"],
    "l": ["x", "y"],
    "t": ["x", "y"],
    "h": ["x"],
    "v": ["y"],
    "s": ["x", "y", "x", "y"],
    "q": ["x", "y", "x", "y"],
    "c": ["x", "y", "x", "y", "x", "y"],
    "a": ["n", "n", "n", "n", "n", "x", "y"],
    "Z": [],
    "z": [],
}


@dataclass(frozen=True)
class Token:
    kind: str
    value: str


@dataclass(frozen=True)
class PathRef:
    template_key: Tuple[str, Tuple[int, ...], bytes]
    offset: Tuple[int, int]


@dataclass
class FileModel:
    stem: str
    family: str
    transposition: int
    rotation: int
    skeleton: str
    href_values: List[str]
    style_values: List[str]
    path_refs: List[PathRef]


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
        help="Print compact JSON summary.",
    )
    return parser.parse_args()


def assert_equal(label: str, got, expected) -> None:
    if got != expected:
        raise AssertionError(f"{label}: expected {expected}, got {got}")


def parse_regular_scale_stem(stem: str) -> Tuple[int, str, int]:
    parts = stem.split(",")
    if len(parts) != 4:
        raise AssertionError(f"{stem}: expected regular scales stem with 4 tokens")
    kind, trans_token, family, rotation_token = parts
    if kind != "scales":
        raise AssertionError(f"{stem}: expected kind token 'scales'")
    if family not in EXPECTED_FAMILIES:
        raise AssertionError(f"{stem}: unexpected family token {family!r}")
    try:
        trans = int(trans_token)
        rotation = int(rotation_token)
    except ValueError as exc:
        raise AssertionError(f"{stem}: invalid numeric token: {exc}") from exc

    if trans not in EXPECTED_TRANS:
        raise AssertionError(f"{stem}: unexpected transposition {trans}")
    expected_rotation = (7 * trans) % 12
    if rotation != expected_rotation:
        raise AssertionError(f"{stem}: expected rotation {expected_rotation}, got {rotation}")

    return trans, family, rotation


def dec_to_i128(text: str) -> int:
    neg = False
    if text.startswith("+"):
        text = text[1:]
    elif text.startswith("-"):
        neg = True
        text = text[1:]

    if "." in text:
        int_part, frac_part = text.split(".", 1)
    else:
        int_part, frac_part = text, ""

    if int_part == "":
        int_part = "0"

    frac_part = (frac_part + ("0" * 17))[:17]
    value = int(int_part) * SCALE + int(frac_part)
    return -value if neg else value


def tokenize_path(path_d: str) -> List[Token]:
    out: List[Token] = []
    i = 0
    n = len(path_d)
    while i < n:
        ch = path_d[i]
        if ch.isalpha():
            out.append(Token("cmd", ch))
            i += 1
            continue

        m = NUM_RE.match(path_d, i)
        if m:
            out.append(Token("num", m.group(0)))
            i = m.end()
            continue

        j = i + 1
        while j < n:
            if path_d[j].isalpha() or NUM_RE.match(path_d, j):
                break
            j += 1
        out.append(Token("sep", path_d[i:j]))
        i = j
    return out


def make_template(path_d: str) -> PathRef:
    toks = tokenize_path(path_d)

    cmd = None
    first_pair: List[int] = []
    for tok in toks:
        if tok.kind == "cmd":
            cmd = tok.value
            continue
        if tok.kind == "num" and cmd == "M":
            first_pair.append(dec_to_i128(tok.value))
            if len(first_pair) == 2:
                break

    dx = first_pair[0] if len(first_pair) > 0 else 0
    dy = first_pair[1] if len(first_pair) > 1 else 0

    parts: List[Tuple[str, str | int]] = []
    bases: List[int] = []
    flags: List[int] = []

    cmd = None
    arg_i = 0
    set_count = 0

    for tok in toks:
        if tok.kind == "cmd":
            cmd = tok.value
            arg_i = 0
            set_count = 0
            parts.append(("lit", tok.value))
            continue
        if tok.kind == "sep":
            parts.append(("lit", tok.value))
            continue
        if cmd is None:
            parts.append(("lit", tok.value))
            continue

        arg_flags = ARG_FLAGS.get(cmd, [])
        if not arg_flags:
            parts.append(("lit", tok.value))
            continue

        if arg_i >= len(arg_flags):
            set_count += 1
            arg_i = 0
            if cmd == "M" and set_count >= 1:
                cmd = "L"
                arg_flags = ARG_FLAGS[cmd]
            elif cmd == "m" and set_count >= 1:
                cmd = "l"
                arg_flags = ARG_FLAGS[cmd]
            else:
                arg_flags = ARG_FLAGS.get(cmd, [])

        axis_flag = arg_flags[arg_i] if arg_i < len(arg_flags) else "n"
        v = dec_to_i128(tok.value)
        out_flag = 0
        if cmd.isupper():
            if axis_flag == "x":
                v -= dx
                out_flag = 1
            elif axis_flag == "y":
                v -= dy
                out_flag = 2

        bases.append(v)
        flags.append(out_flag)
        parts.append(("slot", len(bases) - 1))
        arg_i += 1

    fmt = "".join(payload if kind == "lit" else MARKER_NUM for kind, payload in parts)
    key = (fmt, tuple(bases), bytes(flags))
    return PathRef(template_key=key, offset=(dx, dy))


def parse_svg_model(svg_text: str) -> Tuple[str, List[str], List[str], List[PathRef]]:
    pos = 0
    out_parts: List[str] = []
    href_values: List[str] = []
    style_values: List[str] = []
    path_refs: List[PathRef] = []

    for m in TAG_RE.finditer(svg_text):
        out_parts.append(svg_text[pos : m.start()])
        closing, name, attrs = m.group(1), m.group(2), m.group(3)
        lname = name.lower()

        if closing:
            out_parts.append(m.group(0))
            pos = m.end()
            continue

        if lname in ("a", "path"):
            rebuilt = ["<" + name]
            last = 0
            for am in ATTR_RE.finditer(attrs):
                rebuilt.append(attrs[last : am.start()])
                key, value = am.group(1), am.group(2)
                if lname == "a" and key == "href":
                    href_values.append(value)
                    rebuilt.append(f'{key}="{MARKER_HREF}"')
                elif lname == "path" and key == "style":
                    style_values.append(value)
                    rebuilt.append(f'{key}="{MARKER_STYLE}"')
                elif lname == "path" and key == "d":
                    path_refs.append(make_template(value))
                    rebuilt.append(f'{key}="{MARKER_D}"')
                else:
                    rebuilt.append(am.group(0))
                last = am.end()
            rebuilt.append(attrs[last:])
            rebuilt.append(">")
            out_parts.append("".join(rebuilt))
        else:
            out_parts.append(m.group(0))

        pos = m.end()

    out_parts.append(svg_text[pos:])
    return "".join(out_parts), href_values, style_values, path_refs


def count_dynamic_slots(rows: Sequence[Sequence[object]]) -> Tuple[int, int]:
    if not rows:
        return 0, 0
    width = len(rows[0])
    dynamic = 0
    static = 0
    for i in range(width):
        values = {row[i] for row in rows}
        if len(values) == 1:
            static += 1
        else:
            dynamic += 1
    return static, dynamic


def assert_transposition_domain(values: Iterable[int], label: str) -> None:
    got = sorted(set(values))
    expected = list(EXPECTED_TRANS)
    if got != expected:
        raise AssertionError(f"{label}: transposition domain mismatch: got={got} expected={expected}")


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    majmin_dir = root / "majmin"
    if not majmin_dir.is_dir():
        raise FileNotFoundError(f"missing majmin directory: {majmin_dir}")

    regular_files = []
    for svg_path in sorted(majmin_dir.glob("scales,*.svg")):
        stem = svg_path.stem
        if ",," in stem:
            continue
        regular_files.append(svg_path)

    assert_equal("regular scales file count", len(regular_files), EXPECTED_REGULAR_FILES)

    groups: Dict[str, List[FileModel]] = collections.defaultdict(list)
    for svg_path in regular_files:
        stem = svg_path.stem
        transposition, family, rotation = parse_regular_scale_stem(stem)
        skeleton, href_values, style_values, path_refs = parse_svg_model(svg_path.read_text(encoding="utf-8"))
        groups[family].append(
            FileModel(
                stem=stem,
                family=family,
                transposition=transposition,
                rotation=rotation,
                skeleton=skeleton,
                href_values=href_values,
                style_values=style_values,
                path_refs=path_refs,
            )
        )

    assert_equal("scale family group count", len(groups), len(EXPECTED_FAMILIES))

    family_report = {}
    for family in EXPECTED_FAMILIES:
        rows = sorted(groups.get(family, []), key=lambda row: row.transposition)
        if not rows:
            raise AssertionError(f"missing family group: {family}")

        assert_equal(f"{family}: file count", len(rows), 12)
        assert_transposition_domain((row.transposition for row in rows), f"{family}: transpositions")

        href_count = len(rows[0].href_values)
        style_count = len(rows[0].style_values)
        path_count = len(rows[0].path_refs)
        assert_equal(f"{family}: href slot count", href_count, EXPECTED_HREF_SLOTS)
        assert_equal(f"{family}: style slot count", style_count, EXPECTED_STYLE_SLOTS)
        assert_equal(f"{family}: path slot count", path_count, EXPECTED_PATH_SLOTS)

        for row in rows[1:]:
            assert_equal(f"{row.stem}: href slot count", len(row.href_values), href_count)
            assert_equal(f"{row.stem}: style slot count", len(row.style_values), style_count)
            assert_equal(f"{row.stem}: path slot count", len(row.path_refs), path_count)

        skeleton_variants = {row.skeleton for row in rows}
        assert_equal(f"{family}: skeleton variants", len(skeleton_variants), 1)

        href_static, href_dynamic = count_dynamic_slots([row.href_values for row in rows])
        style_static, style_dynamic = count_dynamic_slots([row.style_values for row in rows])
        path_template_static, path_template_dynamic = count_dynamic_slots(
            [[ref.template_key for ref in row.path_refs] for row in rows]
        )
        path_offset_static, path_offset_dynamic = count_dynamic_slots(
            [[ref.offset for ref in row.path_refs] for row in rows]
        )

        assert_equal(f"{family}: href static slots", href_static, 0)
        assert_equal(f"{family}: href dynamic slots", href_dynamic, EXPECTED_HREF_SLOTS)
        assert_equal(f"{family}: style static slots", style_static, EXPECTED_STYLE_STATIC)
        assert_equal(f"{family}: style dynamic slots", style_dynamic, EXPECTED_STYLE_DYNAMIC)
        assert_equal(f"{family}: path template static slots", path_template_static, EXPECTED_PATH_STATIC)
        assert_equal(f"{family}: path template dynamic slots", path_template_dynamic, EXPECTED_PATH_DYNAMIC)
        assert_equal(f"{family}: path offset static slots", path_offset_static, EXPECTED_PATH_STATIC)
        assert_equal(f"{family}: path offset dynamic slots", path_offset_dynamic, EXPECTED_PATH_DYNAMIC)

        family_report[family] = {
            "files": len(rows),
            "skeleton_variants": len(skeleton_variants),
            "href_slots": href_count,
            "style_slots": style_count,
            "path_slots": path_count,
            "href_static": href_static,
            "href_dynamic": href_dynamic,
            "style_static": style_static,
            "style_dynamic": style_dynamic,
            "path_template_static": path_template_static,
            "path_template_dynamic": path_template_dynamic,
            "path_offset_static": path_offset_static,
            "path_offset_dynamic": path_offset_dynamic,
            "sample": rows[0].stem,
        }

    cross_family_report = []
    by_family_trans: Dict[Tuple[str, int], FileModel] = {}
    for family, rows in groups.items():
        for row in rows:
            by_family_trans[(family, row.transposition)] = row

    for transposition in EXPECTED_TRANS:
        rows = [by_family_trans[(family, transposition)] for family in EXPECTED_FAMILIES]
        base = rows[0]
        style_shared = sum(
            1 for idx in range(len(base.style_values)) if len({row.style_values[idx] for row in rows}) == 1
        )
        path_shared = sum(
            1
            for idx in range(len(base.path_refs))
            if len({(row.path_refs[idx].template_key, row.path_refs[idx].offset) for row in rows}) == 1
        )
        assert_equal(f"t={transposition}: style slots shared across families", style_shared, EXPECTED_STYLE_SLOTS)
        assert_equal(
            f"t={transposition}: path slots shared across families",
            path_shared,
            EXPECTED_CROSS_FAMILY_SHARED_PATH_SLOTS,
        )
        cross_family_report.append(
            {
                "transposition": transposition,
                "style_slots_shared": style_shared,
                "path_slots_shared": path_shared,
            }
        )

    summary = {
        "root": str(root),
        "majmin_dir": str(majmin_dir),
        "regular_files": len(regular_files),
        "families": family_report,
        "cross_family": cross_family_report,
        "expected": {
            "families": list(EXPECTED_FAMILIES),
            "transpositions": list(EXPECTED_TRANS),
            "regular_files": EXPECTED_REGULAR_FILES,
            "href_slots": EXPECTED_HREF_SLOTS,
            "style_slots": EXPECTED_STYLE_SLOTS,
            "path_slots": EXPECTED_PATH_SLOTS,
            "style_static": EXPECTED_STYLE_STATIC,
            "style_dynamic": EXPECTED_STYLE_DYNAMIC,
            "path_static": EXPECTED_PATH_STATIC,
            "path_dynamic": EXPECTED_PATH_DYNAMIC,
            "cross_family_path_shared": EXPECTED_CROSS_FAMILY_SHARED_PATH_SLOTS,
        },
    }

    if args.json:
        print(json.dumps(summary, separators=(",", ":"), sort_keys=True))
    else:
        print(json.dumps(summary, indent=2, sort_keys=True))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
