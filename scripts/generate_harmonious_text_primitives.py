#!/usr/bin/env python3
"""Generate compact symbolic text primitives for harmoniousapp compatibility.

Emits:
  - src/generated/harmonious_text_primitives.zig

The generated model replaces per-stem vertical path lookup tables with
symbol-level primitive composition while preserving exact byte parity.
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import re
import sys
from dataclasses import dataclass
from typing import Dict, Iterable, List, Sequence, Tuple


SCALE = 10_000
EXPECTED_VERTICAL_FILE_COUNTS = {
    "vert-text-black": 115,
    "vert-text-b2t-black": 115,
}
EXPECTED_CENTER_FILE_COUNT = 24
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
ALPHABET = "-0123456789Z"

PATH_D_RE = re.compile(r'<path[^>]*\sd="([^"]+)"')
SUBPATH_RE = re.compile(r"M([+-]?\d*\.?\d+),?([+-]?\d*\.?\d+)([^M]*)")


def fail(msg: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"[generate_harmonious_text_primitives] FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", default="tmp/harmoniousapp.net", help="harmoniousapp root directory")
    p.add_argument(
        "--out",
        default="src/generated/harmonious_text_primitives.zig",
        help="output zig file",
    )
    return p.parse_args()


@dataclass(frozen=True)
class SubPath:
    x_raw: str
    y_raw: str
    x: int
    y: int
    body: str


@dataclass(frozen=True)
class VerticalRecord:
    kind: str
    stem: str
    text: str
    subpaths: Tuple[SubPath, ...]


@dataclass(frozen=True)
class CenterRecord:
    stem: str
    path_d: str


def parse_decimal_scaled(raw: str) -> int:
    s = raw.strip()
    if not s:
        fail("empty numeric token")
    sign = 1
    if s[0] == "-":
        sign = -1
        s = s[1:]
    elif s[0] == "+":
        s = s[1:]

    if "." in s:
        whole_s, frac_s = s.split(".", 1)
    else:
        whole_s, frac_s = s, ""

    if whole_s == "":
        whole = 0
    elif whole_s.isdigit():
        whole = int(whole_s)
    else:
        fail(f"invalid numeric token '{raw}'")

    if frac_s and not frac_s.isdigit():
        fail(f"invalid numeric token '{raw}'")

    if len(frac_s) > 4:
        fail(f"numeric precision > 4 decimals in '{raw}'")

    frac = int((frac_s + "0000")[:4]) if frac_s else 0
    return sign * (whole * SCALE + frac)


def fmt_scaled(value: int) -> str:
    if value == 0:
        return "0"
    sign = "-" if value < 0 else ""
    mag = -value if value < 0 else value
    whole = mag // SCALE
    frac = mag % SCALE
    if frac == 0:
        return f"{sign}{whole}"
    frac_s = f"{frac:04d}".rstrip("0")
    return f"{sign}{whole}.{frac_s}"


def zig_str(text: str) -> str:
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def parse_vertical_record(kind: str, svg_path: pathlib.Path) -> VerticalRecord:
    text = svg_path.read_text(encoding="utf-8")
    m = PATH_D_RE.search(text)
    if not m:
        fail(f"{svg_path}: missing path d attribute")
    d = m.group(1)

    subpaths: List[SubPath] = []
    for sm in SUBPATH_RE.finditer(d):
        x_raw = sm.group(1)
        y_raw = sm.group(2)
        body = sm.group(3)
        subpaths.append(
            SubPath(
                x_raw=x_raw,
                y_raw=y_raw,
                x=parse_decimal_scaled(x_raw),
                y=parse_decimal_scaled(y_raw),
                body=body,
            )
        )

    if not subpaths:
        fail(f"{svg_path}: no subpaths parsed")

    stem = svg_path.stem
    if any(ch not in EXPECTED_PRIMITIVE_COUNTS for ch in stem):
        bad = sorted({ch for ch in stem if ch not in EXPECTED_PRIMITIVE_COUNTS})
        fail(f"{svg_path}: unexpected stem chars {bad}")

    return VerticalRecord(kind=kind, stem=stem, text=stem, subpaths=tuple(subpaths))


def collect_vertical_records(root: pathlib.Path) -> List[VerticalRecord]:
    out: List[VerticalRecord] = []
    for kind, expected_count in EXPECTED_VERTICAL_FILE_COUNTS.items():
        d = root / kind
        if not d.is_dir():
            fail(f"missing directory: {d}")
        files = sorted(d.glob("*.svg"))
        if len(files) != expected_count:
            fail(f"{kind}: expected {expected_count} files, found {len(files)}")
        for p in files:
            out.append(parse_vertical_record(kind, p))
    return out


def collect_center_records(root: pathlib.Path) -> List[CenterRecord]:
    d = root / "center-square-text"
    if not d.is_dir():
        fail(f"missing directory: {d}")
    files = sorted(d.glob("*.svg"))
    if len(files) != EXPECTED_CENTER_FILE_COUNT:
        fail(f"center-square-text: expected {EXPECTED_CENTER_FILE_COUNT} files, found {len(files)}")
    out: List[CenterRecord] = []
    for p in files:
        m = PATH_D_RE.search(p.read_text(encoding="utf-8"))
        if not m:
            fail(f"{p}: missing path d attribute")
        out.append(CenterRecord(stem=p.stem, path_d=m.group(1)))
    return out


def assign_symbol_parts(records: Sequence[VerticalRecord]):
    body_to_id: Dict[str, int] = {}
    body_freq: collections.Counter[int] = collections.Counter()
    char_freq: collections.Counter[str] = collections.Counter()

    for rec in records:
        for ch in rec.text:
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

    expected_primitive_count = sum(EXPECTED_PRIMITIVE_COUNTS.values())
    if len(body_to_id) != expected_primitive_count:
        fail(
            f"primitive body count mismatch: expected {expected_primitive_count}, "
            f"found {len(body_to_id)}"
        )

    candidates: Dict[str, List[int]] = {}
    for ch, freq in sorted(char_freq.items()):
        candidates[ch] = sorted(bid for bid, c in body_freq.items() if c == freq)

    assigned: Dict[str, List[int]] = {}
    for ch, body_ids in candidates.items():
        expected_parts = EXPECTED_PRIMITIVE_COUNTS[ch]
        if len(body_ids) == expected_parts and expected_parts > 1:
            assigned[ch] = body_ids

    # Single-part symbols with unique frequency map directly.
    for ch, expected_parts in EXPECTED_PRIMITIVE_COUNTS.items():
        if expected_parts != 1:
            continue
        body_ids = candidates[ch]
        if len(body_ids) == 1:
            assigned[ch] = body_ids

    rec_by_key = {(r.kind, r.stem): r for r in records}
    for stem, ch in (("4-1", "4"), ("5-1", "5")):
        rec = rec_by_key.get(("vert-text-b2t-black", stem))
        if rec is None:
            fail(f"missing disambiguation stem vert-text-b2t-black/{stem}.svg")
        ids = [body_to_id[sub.body] for sub in rec.subpaths]
        if not ids:
            fail(f"disambiguation stem {stem} has no subpaths")
        assigned[ch] = [ids[0]]

    for ch, expected_parts in EXPECTED_PRIMITIVE_COUNTS.items():
        got = assigned.get(ch)
        if got is None:
            fail(f"no body assignment for symbol '{ch}'")
        if len(got) != expected_parts:
            fail(f"symbol '{ch}' primitive count mismatch: expected {expected_parts}, got {len(got)}")

    ordered: Dict[str, List[int]] = {}

    for ch, expected_parts in EXPECTED_PRIMITIVE_COUNTS.items():
        if expected_parts == 1:
            ordered[ch] = assigned[ch]

    for ch in ("6", "8", "9"):
        rec = next((r for r in records if r.stem.startswith(f"{ch}-")), None)
        if rec is None:
            fail(f"missing prefix inference stem for '{ch}'")
        ids = [body_to_id[sub.body] for sub in rec.subpaths]
        ordered[ch] = ids[: EXPECTED_PRIMITIVE_COUNTS[ch]]

    rec_10 = next((r for r in records if r.stem.endswith("-10")), None)
    if rec_10 is None:
        fail("missing '*-10' stem for '0' ordering inference")
    ids_10 = [body_to_id[sub.body] for sub in rec_10.subpaths]
    first_char = rec_10.stem[0]
    start = EXPECTED_PRIMITIVE_COUNTS[first_char] + EXPECTED_PRIMITIVE_COUNTS["-"] + EXPECTED_PRIMITIVE_COUNTS["1"]
    ordered["0"] = ids_10[start : start + EXPECTED_PRIMITIVE_COUNTS["0"]]

    for ch, seq in ordered.items():
        if len(seq) != EXPECTED_PRIMITIVE_COUNTS[ch]:
            fail(f"ordered part count mismatch for '{ch}'")
        if sorted(seq) != sorted(assigned[ch]):
            fail(f"ordered assignment mismatch for '{ch}'")

    # Validate segmentation and collect symbol occurrences.
    symbol_occurrences: Dict[str, List[List[SubPath]]] = {ch: [] for ch in EXPECTED_PRIMITIVE_COUNTS}
    record_symbol_parts: Dict[Tuple[str, str], List[List[SubPath]]] = {}
    for rec in records:
        ids = [body_to_id[s.body] for s in rec.subpaths]
        cursor = 0
        symbols: List[List[SubPath]] = []
        for ch in rec.text:
            seq = ordered[ch]
            n = len(seq)
            got = ids[cursor : cursor + n]
            if got != seq:
                fail(
                    f"segmentation mismatch {rec.kind}/{rec.stem} at {cursor}: expected {seq}, got {got}"
                )
            part_slice = list(rec.subpaths[cursor : cursor + n])
            symbols.append(part_slice)
            symbol_occurrences[ch].append(part_slice)
            cursor += n
        if cursor != len(ids):
            fail(f"segmentation overrun {rec.kind}/{rec.stem}: used {cursor}, have {len(ids)}")
        record_symbol_parts[(rec.kind, rec.stem)] = symbols

    # Build deterministic primitive ordering by symbol and in-symbol order.
    primitive_ids: List[int] = []
    for ch in ALPHABET:
        primitive_ids.extend(ordered[ch])
    if len(set(primitive_ids)) != len(body_to_id):
        fail("primitive ordering failed to cover all primitive IDs")

    old_to_new = {old: i for i, old in enumerate(primitive_ids)}
    id_to_body_old = [None] * len(body_to_id)
    for body, old in body_to_id.items():
        id_to_body_old[old] = body
    primitive_bodies = [id_to_body_old[old] for old in primitive_ids]

    symbol_parts_new: Dict[str, List[int]] = {
        ch: [old_to_new[old] for old in ordered[ch]] for ch in ALPHABET
    }

    return (
        primitive_bodies,
        symbol_parts_new,
        record_symbol_parts,
    )


def derive_symbol_offsets(
    symbol_parts_new: Dict[str, List[int]],
    record_symbol_parts: Dict[Tuple[str, str], List[List[SubPath]]],
):
    # symbol_offsets[ch] = list[(dx,dy)] in part order
    symbol_offsets: Dict[str, List[Tuple[int, int]]] = {}

    for ch in ALPHABET:
        expected_parts = len(symbol_parts_new[ch])
        reference: List[Tuple[int, int]] | None = None

        for (_kind, stem), symbols in record_symbol_parts.items():
            idx = 0
            for sym_ch in stem:
                part_group = symbols[idx]
                idx += 1
                if sym_ch != ch:
                    continue
                if len(part_group) != expected_parts:
                    fail(f"symbol part count mismatch for '{ch}' in {stem}")
                origin = part_group[0]
                offsets = [(p.x - origin.x, p.y - origin.y) for p in part_group]
                if reference is None:
                    reference = offsets
                elif reference != offsets:
                    fail(f"non-deterministic part offsets for symbol '{ch}'")

        if reference is None:
            fail(f"no occurrences found for symbol '{ch}'")

        symbol_offsets[ch] = reference

    return symbol_offsets


def derive_orientation_models(
    records: Sequence[VerticalRecord],
    symbol_offsets: Dict[str, List[Tuple[int, int]]],
    record_symbol_parts: Dict[Tuple[str, str], List[List[SubPath]]],
):
    models = {}

    for kind in ("vert-text-black", "vert-text-b2t-black"):
        orient_records = [r for r in records if r.kind == kind]

        pair_delta_map: Dict[Tuple[str, str], Tuple[int, int]] = {}
        first_y_map: Dict[str, int] = {}
        edge_bias_map: Dict[Tuple[str, str], int] = {}

        for rec in orient_records:
            symbol_groups = record_symbol_parts[(rec.kind, rec.stem)]
            origins = [
                (group[0].x - symbol_offsets[ch][0][0], group[0].y - symbol_offsets[ch][0][1])
                for ch, group in zip(rec.text, symbol_groups)
            ]

            # first_y by first char
            first = rec.text[0]
            y0 = origins[0][1]
            prev_y = first_y_map.get(first)
            if prev_y is None:
                first_y_map[first] = y0
            elif prev_y != y0:
                fail(f"non-deterministic first_y for {kind} char '{first}'")

            total_dx = 0
            for i in range(len(rec.text) - 1):
                a = rec.text[i]
                b = rec.text[i + 1]
                dx = origins[i + 1][0] - origins[i][0]
                dy = origins[i + 1][1] - origins[i][1]
                key = (a, b)
                prev = pair_delta_map.get(key)
                if prev is None:
                    pair_delta_map[key] = (dx, dy)
                elif prev != (dx, dy):
                    fail(f"non-deterministic pair delta for {kind} pair {a}->{b}")
                total_dx += dx

            edge_key = (rec.text[0], rec.text[-1])
            bias2 = 2 * origins[0][0] + total_dx
            prev_bias2 = edge_bias_map.get(edge_key)
            if prev_bias2 is None:
                edge_bias_map[edge_key] = bias2
            elif prev_bias2 != bias2:
                fail(f"non-deterministic edge bias for {kind} edge {edge_key}")

        models[kind] = {
            "pair_deltas": pair_delta_map,
            "first_y": first_y_map,
            "edge_bias2": edge_bias_map,
            "use_comma": (kind == "vert-text-b2t-black"),
        }

    return models


def roundtrip_full_paths(
    records: Sequence[VerticalRecord],
    symbol_offsets: Dict[str, List[Tuple[int, int]]],
    symbol_parts_new: Dict[str, List[int]],
    primitive_bodies: Sequence[str],
    models,
):
    for rec in records:
        model = models[rec.kind]
        pair_delta_map = model["pair_deltas"]
        first_y_map = model["first_y"]
        edge_bias_map = model["edge_bias2"]
        use_comma = model["use_comma"]

        total_dx = 0
        pair_deltas: List[Tuple[int, int]] = []
        for i in range(len(rec.text) - 1):
            pair = (rec.text[i], rec.text[i + 1])
            delta = pair_delta_map.get(pair)
            if delta is None:
                fail(f"missing pair delta for {rec.kind}/{rec.stem} pair {pair}")
            pair_deltas.append(delta)
            total_dx += delta[0]

        edge_key = (rec.text[0], rec.text[-1])
        bias2 = edge_bias_map.get(edge_key)
        if bias2 is None:
            fail(f"missing edge bias2 for {rec.kind}/{rec.stem} edge {edge_key}")
        x0_num = bias2 - total_dx
        if x0_num % 2 != 0:
            fail(f"non-integer x0 for {rec.kind}/{rec.stem}")
        sx = x0_num // 2

        sy = first_y_map.get(rec.text[0])
        if sy is None:
            fail(f"missing first_y for {rec.kind}/{rec.stem}")

        parts_out: List[str] = []
        for i, ch in enumerate(rec.text):
            part_ids = symbol_parts_new[ch]
            offsets = symbol_offsets[ch]
            if len(part_ids) != len(offsets):
                fail(f"part id/offset length mismatch for symbol '{ch}'")
            for pid, (dx, dy) in zip(part_ids, offsets):
                x = sx + dx
                y = sy + dy
                head = f"M{fmt_scaled(x)}{',' if use_comma else ''}{fmt_scaled(y)}"
                parts_out.append(head + primitive_bodies[pid])
            if i + 1 < len(rec.text):
                pdx, pdy = pair_deltas[i]
                sx += pdx
                sy += pdy

        got = "".join(parts_out)
        expected = "".join(
            f"M{sub.x_raw}{',' if use_comma else ''}{sub.y_raw}{sub.body}" for sub in rec.subpaths
        )
        if got != expected:
            fail(
                f"full roundtrip mismatch for {rec.kind}/{rec.stem}\n"
                f"expected={expected}\n"
                f"     got={got}"
            )


def emit_zig(
    out_path: pathlib.Path,
    primitive_bodies: Sequence[str],
    symbol_offsets: Dict[str, List[Tuple[int, int]]],
    symbol_parts_new: Dict[str, List[int]],
    models,
    center_records: Sequence[CenterRecord],
):
    lines: List[str] = []
    lines.append("// Auto-generated from tmp/harmoniousapp.net/{vert-text-black,vert-text-b2t-black,center-square-text}/*.svg")
    lines.append("// DO NOT EDIT MANUALLY.")
    lines.append("")
    lines.append("pub const TextPrimitive = struct {")
    lines.append("    body: []const u8,")
    lines.append("};")
    lines.append("")
    lines.append("pub const SymbolPart = struct {")
    lines.append("    primitive_index: u8,")
    lines.append("    dx: i32,")
    lines.append("    dy: i32,")
    lines.append("};")
    lines.append("")
    lines.append("pub const SymbolDef = struct {")
    lines.append("    ch: u8,")
    lines.append("    parts: []const SymbolPart,")
    lines.append("};")
    lines.append("")
    lines.append("pub const PairDelta = struct {")
    lines.append("    prev: u8,")
    lines.append("    next: u8,")
    lines.append("    dx: i32,")
    lines.append("    dy: i32,")
    lines.append("};")
    lines.append("")
    lines.append("pub const EdgeBias = struct {")
    lines.append("    first: u8,")
    lines.append("    last: u8,")
    lines.append("    bias2: i32,")
    lines.append("};")
    lines.append("")
    lines.append("pub const FirstY = struct {")
    lines.append("    first: u8,")
    lines.append("    y: i32,")
    lines.append("};")
    lines.append("")
    lines.append("pub const OrientationModel = struct {")
    lines.append("    use_comma: bool,")
    lines.append("    pair_deltas: []const PairDelta,")
    lines.append("    edge_biases: []const EdgeBias,")
    lines.append("    first_y: []const FirstY,")
    lines.append("};")
    lines.append("")
    lines.append("pub const CenterSquareTemplate = struct {")
    lines.append("    stem: []const u8,")
    lines.append("    path_d: []const u8,")
    lines.append("};")
    lines.append("")

    lines.append("pub const ALPHABET = \"-0123456789Z\";")
    lines.append("")

    lines.append("pub const PRIMITIVES = [_]TextPrimitive{")
    for body in primitive_bodies:
        lines.append(f"    .{{ .body = {zig_str(body)} }},")
    lines.append("};")
    lines.append("")

    for ch in ALPHABET:
        parts = symbol_parts_new[ch]
        offsets = symbol_offsets[ch]
        lines.append(f"pub const PARTS_{ch if ch.isalnum() else 'dash'} = [_]SymbolPart{{")
        for pid, (dx, dy) in zip(parts, offsets):
            lines.append(f"    .{{ .primitive_index = {pid}, .dx = {dx}, .dy = {dy} }},")
        lines.append("};")
        lines.append("")

    lines.append("pub const SYMBOLS = [_]SymbolDef{")
    for ch in ALPHABET:
        arr_name = f"PARTS_{ch if ch.isalnum() else 'dash'}"
        lines.append(f"    .{{ .ch = '{ch}', .parts = &{arr_name} }},")
    lines.append("};")
    lines.append("")

    for kind, model_name in (("vert-text-black", "VERT_TEXT_BLACK_MODEL"), ("vert-text-b2t-black", "VERT_TEXT_B2T_BLACK_MODEL")):
        model = models[kind]
        pair_items = sorted(model["pair_deltas"].items())
        edge_items = sorted(model["edge_bias2"].items())
        first_y_items = sorted(model["first_y"].items())

        pair_arr = f"{model_name}_PAIRS"
        edge_arr = f"{model_name}_EDGE_BIASES"
        y_arr = f"{model_name}_FIRST_Y"

        lines.append(f"pub const {pair_arr} = [_]PairDelta{{")
        for (a, b), (dx, dy) in pair_items:
            lines.append(f"    .{{ .prev = '{a}', .next = '{b}', .dx = {dx}, .dy = {dy} }},")
        lines.append("};")
        lines.append("")

        lines.append(f"pub const {edge_arr} = [_]EdgeBias{{")
        for (a, b), bias2 in edge_items:
            lines.append(f"    .{{ .first = '{a}', .last = '{b}', .bias2 = {bias2} }},")
        lines.append("};")
        lines.append("")

        lines.append(f"pub const {y_arr} = [_]FirstY{{")
        for a, y in first_y_items:
            lines.append(f"    .{{ .first = '{a}', .y = {y} }},")
        lines.append("};")
        lines.append("")

        use_comma = "true" if model["use_comma"] else "false"
        lines.append(f"pub const {model_name} = OrientationModel{{")
        lines.append(f"    .use_comma = {use_comma},")
        lines.append(f"    .pair_deltas = &{pair_arr},")
        lines.append(f"    .edge_biases = &{edge_arr},")
        lines.append(f"    .first_y = &{y_arr},")
        lines.append("};")
        lines.append("")

    lines.append("pub const CENTER_SQUARE_TEXT = [_]CenterSquareTemplate{")
    for rec in center_records:
        lines.append(f"    .{{ .stem = {zig_str(rec.stem)}, .path_d = {zig_str(rec.path_d)} }},")
    lines.append("};")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    root = pathlib.Path(args.root)
    out = pathlib.Path(args.out)

    vertical_records = collect_vertical_records(root)
    center_records = collect_center_records(root)

    primitive_bodies, symbol_parts_new, record_symbol_parts = assign_symbol_parts(vertical_records)
    symbol_offsets = derive_symbol_offsets(symbol_parts_new, record_symbol_parts)
    models = derive_orientation_models(vertical_records, symbol_offsets, record_symbol_parts)

    roundtrip_full_paths(
        vertical_records,
        symbol_offsets,
        symbol_parts_new,
        primitive_bodies,
        models,
    )

    emit_zig(
        out_path=out,
        primitive_bodies=primitive_bodies,
        symbol_offsets=symbol_offsets,
        symbol_parts_new=symbol_parts_new,
        models=models,
        center_records=center_records,
    )

    print("[generate_harmonious_text_primitives] PASS")
    print(f"[generate_harmonious_text_primitives] output: {out}")
    print(f"[generate_harmonious_text_primitives] primitives: {len(primitive_bodies)}")
    print(f"[generate_harmonious_text_primitives] vertical_records: {len(vertical_records)}")
    print(f"[generate_harmonious_text_primitives] center_records: {len(center_records)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
