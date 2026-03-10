#!/usr/bin/env python3
"""
Generate compact majmin scene pack for algorithmic compatibility rendering.

Input:
  tmp/harmoniousapp.net/majmin/*.svg

Output:
  src/generated/harmonious_majmin_scene_pack_xz.zig
"""

from __future__ import annotations

import argparse
import glob
import lzma
import os
import re
import struct
from dataclasses import dataclass
from typing import Dict, List, Tuple

SCALE = 10**17

TAG_RE = re.compile(r"<(/?)([a-zA-Z]+)([^>]*)>")
ATTR_RE = re.compile(r'([a-zA-Z_:][\w:.-]*)="([^"]*)"')
NUM_RE = re.compile(r"[+-]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?")

MARKER_HREF = "\x1d"
MARKER_STYLE = "\x1e"
MARKER_D = "\x1f"
MARKER_NUM = "\x01"

FAMILIES = ("dntri", "hex", "rhomb", "uptri")
MODE_TRANS_ORDER = (-1, 0, 1, 10, 11, 2, 3, 4, 5, 6, 7, 8, 9)
SCALE_TRANS_ORDER = tuple(range(12))
MODE_ROTATIONS_BY_FAMILY = {
    "dntri": (0, 1, 10, 11, 3, 4, 7),
    "hex": (0, 1, 10, 11, 7, 8, 9),
    "rhomb": (0, 1, 10, 11, 3, 7, 9),
    "uptri": (0, 1, 10, 11, 4, 7, 8),
}

LEGACY_FILES = (
    ("modes", 1, "modes,-1,,-3,1.svg"),
    ("modes", 2, "modes,-1,,-3,2.svg"),
    ("scales", 1, "scales,-1,,0,1.svg"),
    ("scales", 2, "scales,-1,,0,2.svg"),
)

FAMILY_ID = {"dntri": 0, "hex": 1, "rhomb": 2, "uptri": 3}
KIND_ID = {"modes": 0, "scales": 1}

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


@dataclass
class ParsedFile:
    skeleton_id: int
    href_ids: List[int]
    style_ids: List[int]
    d_refs: List[Tuple[int, int]]


@dataclass
class ModeGroupRecord:
    family: str
    rotation: int
    skeleton_id: int
    href_slot_base: List[int]
    style_slot_base: List[int]
    d_slot_base: List[int]
    href_map: List[List[int]]
    style_map: List[List[int]]
    d_map: List[List[Tuple[int, int]]]


@dataclass
class ScaleFamilyRecord:
    family: str
    skeleton_id: int
    href_slot_base: List[int]
    style_slot_base: List[int]
    d_slot_base: List[int]
    href_map: List[List[int]]
    style_map: List[List[int]]
    d_map: List[List[Tuple[int, int]]]


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


def make_template(path_d: str) -> tuple[tuple[str, tuple[int, ...], bytes], tuple[int, int]]:
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

    fmt_parts: List[str] = []
    for kind, payload in parts:
        if kind == "lit":
            fmt_parts.append(payload)  # type: ignore[arg-type]
        else:
            fmt_parts.append(MARKER_NUM)
    fmt = "".join(fmt_parts)

    key = (fmt, tuple(bases), bytes(flags))
    return key, (dx, dy)


def parse_file(svg_text: str) -> tuple[str, List[str], List[str], List[str]]:
    pos = 0
    out_parts: List[str] = []
    href_values: List[str] = []
    style_values: List[str] = []
    d_values: List[str] = []

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
                    d_values.append(value)
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
    return "".join(out_parts), href_values, style_values, d_values


def intern(intern_map: Dict, arr: List, value):
    existing = intern_map.get(value)
    if existing is not None:
        return existing
    idx = len(arr)
    intern_map[value] = idx
    arr.append(value)
    return idx


def read_svg(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def parse_regular_svg(
    path: str,
    skeleton_map: Dict[str, int],
    style_map: Dict[str, int],
    href_map: Dict[str, int],
    template_map: Dict[tuple[str, tuple[int, ...], bytes], int],
    offset_map: Dict[tuple[int, int], int],
    skeletons: List[str],
    styles: List[str],
    hrefs: List[str],
    templates: List[tuple[str, tuple[int, ...], bytes]],
    offsets: List[tuple[int, int]],
) -> ParsedFile:
    svg_text = read_svg(path)
    skeleton, href_vals, style_vals, d_vals = parse_file(svg_text)

    skeleton_id = intern(skeleton_map, skeletons, skeleton)
    href_ids = [intern(href_map, hrefs, h) for h in href_vals]
    style_ids = [intern(style_map, styles, s) for s in style_vals]

    d_refs: List[Tuple[int, int]] = []
    for d in d_vals:
        tpl_key, off = make_template(d)
        tid = intern(template_map, templates, tpl_key)
        oid = intern(offset_map, offsets, off)
        d_refs.append((tid, oid))

    return ParsedFile(
        skeleton_id=skeleton_id,
        href_ids=href_ids,
        style_ids=style_ids,
        d_refs=d_refs,
    )


def build_mode_group(
    family: str,
    rotation: int,
    regular: Dict[tuple[str, int, str, int], ParsedFile],
) -> ModeGroupRecord:
    base = regular[("modes", -1, family, rotation)]

    href_base: List[int] = []
    href_base_idx: Dict[int, int] = {}
    href_slot_base: List[int] = []
    for value in base.href_ids:
        idx = href_base_idx.get(value)
        if idx is None:
            idx = len(href_base)
            href_base_idx[value] = idx
            href_base.append(value)
        href_slot_base.append(idx)

    style_base: List[int] = []
    style_base_idx: Dict[int, int] = {}
    style_slot_base: List[int] = []
    for value in base.style_ids:
        idx = style_base_idx.get(value)
        if idx is None:
            idx = len(style_base)
            style_base_idx[value] = idx
            style_base.append(value)
        style_slot_base.append(idx)

    d_base: List[Tuple[int, int]] = []
    d_base_idx: Dict[Tuple[int, int], int] = {}
    d_slot_base: List[int] = []
    for value in base.d_refs:
        idx = d_base_idx.get(value)
        if idx is None:
            idx = len(d_base)
            d_base_idx[value] = idx
            d_base.append(value)
        d_slot_base.append(idx)

    href_map: List[List[int]] = []
    style_map: List[List[int]] = []
    d_map: List[List[Tuple[int, int]]] = []

    for transposition in MODE_TRANS_ORDER:
        row = regular[("modes", transposition, family, rotation)]
        if len(row.href_ids) != len(base.href_ids):
            raise ValueError(f"mode group {family}/{rotation}: href count mismatch at t={transposition}")
        if len(row.style_ids) != len(base.style_ids):
            raise ValueError(f"mode group {family}/{rotation}: style count mismatch at t={transposition}")
        if len(row.d_refs) != len(base.d_refs):
            raise ValueError(f"mode group {family}/{rotation}: d count mismatch at t={transposition}")

        href_row = [-1] * len(href_base)
        for slot_base, value in zip(href_slot_base, row.href_ids):
            prev = href_row[slot_base]
            if prev == -1:
                href_row[slot_base] = value
            elif prev != value:
                raise ValueError(f"mode group {family}/{rotation}: inconsistent href mapping at t={transposition}")

        style_row = [-1] * len(style_base)
        for slot_base, value in zip(style_slot_base, row.style_ids):
            prev = style_row[slot_base]
            if prev == -1:
                style_row[slot_base] = value
            elif prev != value:
                raise ValueError(f"mode group {family}/{rotation}: inconsistent style mapping at t={transposition}")

        d_row = [(-1, -1)] * len(d_base)
        for slot_base, value in zip(d_slot_base, row.d_refs):
            prev = d_row[slot_base]
            if prev == (-1, -1):
                d_row[slot_base] = value
            elif prev != value:
                raise ValueError(f"mode group {family}/{rotation}: inconsistent d mapping at t={transposition}")

        if any(x < 0 for x in href_row):
            raise ValueError(f"mode group {family}/{rotation}: incomplete href map at t={transposition}")
        if any(x < 0 for x in style_row):
            raise ValueError(f"mode group {family}/{rotation}: incomplete style map at t={transposition}")
        if any(x[0] < 0 for x in d_row):
            raise ValueError(f"mode group {family}/{rotation}: incomplete d map at t={transposition}")

        href_map.append(href_row)
        style_map.append(style_row)
        d_map.append(d_row)

    return ModeGroupRecord(
        family=family,
        rotation=rotation,
        skeleton_id=base.skeleton_id,
        href_slot_base=href_slot_base,
        style_slot_base=style_slot_base,
        d_slot_base=d_slot_base,
        href_map=href_map,
        style_map=style_map,
        d_map=d_map,
    )


def build_scale_family(
    family: str,
    regular: Dict[tuple[str, int, str, int], ParsedFile],
) -> ScaleFamilyRecord:
    base = regular[("scales", 0, family, 0)]

    href_base: List[int] = []
    href_base_idx: Dict[int, int] = {}
    href_slot_base: List[int] = []
    for value in base.href_ids:
        idx = href_base_idx.get(value)
        if idx is None:
            idx = len(href_base)
            href_base_idx[value] = idx
            href_base.append(value)
        href_slot_base.append(idx)

    style_base: List[int] = []
    style_base_idx: Dict[int, int] = {}
    style_slot_base: List[int] = []
    for value in base.style_ids:
        idx = style_base_idx.get(value)
        if idx is None:
            idx = len(style_base)
            style_base_idx[value] = idx
            style_base.append(value)
        style_slot_base.append(idx)

    d_base: List[Tuple[int, int]] = []
    d_base_idx: Dict[Tuple[int, int], int] = {}
    d_slot_base: List[int] = []
    for value in base.d_refs:
        idx = d_base_idx.get(value)
        if idx is None:
            idx = len(d_base)
            d_base_idx[value] = idx
            d_base.append(value)
        d_slot_base.append(idx)

    href_map: List[List[int]] = []
    style_map: List[List[int]] = []
    d_map: List[List[Tuple[int, int]]] = []

    for transposition in SCALE_TRANS_ORDER:
        rotation = (7 * transposition) % 12
        row = regular[("scales", transposition, family, rotation)]

        href_row = [-1] * len(href_base)
        for slot_base, value in zip(href_slot_base, row.href_ids):
            prev = href_row[slot_base]
            if prev == -1:
                href_row[slot_base] = value
            elif prev != value:
                raise ValueError(f"scale family {family}: inconsistent href mapping at t={transposition}")

        style_row = [-1] * len(style_base)
        for slot_base, value in zip(style_slot_base, row.style_ids):
            prev = style_row[slot_base]
            if prev == -1:
                style_row[slot_base] = value
            elif prev != value:
                raise ValueError(f"scale family {family}: inconsistent style mapping at t={transposition}")

        d_row = [(-1, -1)] * len(d_base)
        for slot_base, value in zip(d_slot_base, row.d_refs):
            prev = d_row[slot_base]
            if prev == (-1, -1):
                d_row[slot_base] = value
            elif prev != value:
                raise ValueError(f"scale family {family}: inconsistent d mapping at t={transposition}")

        if any(x < 0 for x in href_row):
            raise ValueError(f"scale family {family}: incomplete href map at t={transposition}")
        if any(x < 0 for x in style_row):
            raise ValueError(f"scale family {family}: incomplete style map at t={transposition}")
        if any(x[0] < 0 for x in d_row):
            raise ValueError(f"scale family {family}: incomplete d map at t={transposition}")

        href_map.append(href_row)
        style_map.append(style_row)
        d_map.append(d_row)

    return ScaleFamilyRecord(
        family=family,
        skeleton_id=base.skeleton_id,
        href_slot_base=href_slot_base,
        style_slot_base=style_slot_base,
        d_slot_base=d_slot_base,
        href_map=href_map,
        style_map=style_map,
        d_map=d_map,
    )


def pack_u16_array(buf: bytearray, values: List[int]) -> None:
    for v in values:
        buf.extend(struct.pack("<H", v))


def write_u16(buf: bytearray, value: int) -> None:
    buf.extend(struct.pack("<H", value))


def write_u32(buf: bytearray, value: int) -> None:
    buf.extend(struct.pack("<I", value))


def write_i128(buf: bytearray, value: int) -> None:
    buf.extend(int(value).to_bytes(16, byteorder="little", signed=True))


def build_pack(majmin_dir: str) -> tuple[bytes, dict[str, int]]:
    skeleton_map: Dict[str, int] = {}
    style_map: Dict[str, int] = {}
    href_map: Dict[str, int] = {}
    template_map: Dict[tuple[str, tuple[int, ...], bytes], int] = {}
    offset_map: Dict[tuple[int, int], int] = {}

    skeletons: List[str] = []
    styles: List[str] = []
    hrefs: List[str] = []
    templates: List[tuple[str, tuple[int, ...], bytes]] = []
    offsets: List[tuple[int, int]] = []

    regular: Dict[tuple[str, int, str, int], ParsedFile] = {}

    for path in sorted(glob.glob(os.path.join(majmin_dir, "*.svg"))):
        name = os.path.basename(path)
        stem = name[:-4] if name.endswith(".svg") else name
        parts = stem.split(",")
        if len(parts) == 5:
            # legacy overview variants are handled separately below
            continue
        if len(parts) != 4:
            raise ValueError(f"unexpected majmin filename token count: {name}")
        kind, trans_tok, family, rotation_tok = parts
        if kind not in ("modes", "scales"):
            raise ValueError(f"unexpected kind in {name}")
        if family not in FAMILIES:
            raise ValueError(f"unexpected family in {name}")
        transposition = int(trans_tok)
        rotation = int(rotation_tok)
        regular[(kind, transposition, family, rotation)] = parse_regular_svg(
            path,
            skeleton_map,
            style_map,
            href_map,
            template_map,
            offset_map,
            skeletons,
            styles,
            hrefs,
            templates,
            offsets,
        )

    mode_groups: List[ModeGroupRecord] = []
    for family in FAMILIES:
        for rotation in MODE_ROTATIONS_BY_FAMILY[family]:
            mode_groups.append(build_mode_group(family, rotation, regular))

    scale_families: List[ScaleFamilyRecord] = []
    for family in FAMILIES:
        scale_families.append(build_scale_family(family, regular))

    legacy_payloads = []
    for kind, variant, file_name in LEGACY_FILES:
        raw = open(os.path.join(majmin_dir, file_name), "rb").read()
        legacy_payloads.append((kind, variant, raw))

    mode_max_href_slots = max(len(group.href_slot_base) for group in mode_groups)
    mode_max_style_slots = max(len(group.style_slot_base) for group in mode_groups)
    mode_max_d_slots = max(len(group.d_slot_base) for group in mode_groups)
    mode_max_href_base = max(len(group.href_map[0]) for group in mode_groups)
    mode_max_style_base = max(len(group.style_map[0]) for group in mode_groups)
    mode_max_d_base = max(len(group.d_map[0]) for group in mode_groups)

    pack = bytearray()
    pack.extend(b"MJM3\x00\x00\x00\x00")

    write_u32(pack, len(skeletons))
    write_u32(pack, len(styles))
    write_u32(pack, len(hrefs))
    write_u32(pack, len(templates))
    write_u32(pack, len(offsets))
    write_u32(pack, len(mode_groups))
    write_u32(pack, len(scale_families))
    write_u32(pack, len(legacy_payloads))

    for text in skeletons:
        b = text.encode("utf-8", "surrogatepass")
        write_u32(pack, len(b))
        pack.extend(b)

    for text in styles:
        b = text.encode("utf-8")
        write_u16(pack, len(b))
        pack.extend(b)

    for text in hrefs:
        b = text.encode("utf-8")
        write_u16(pack, len(b))
        pack.extend(b)

    for fmt, base_vals, flags in templates:
        fb = fmt.encode("utf-8", "surrogatepass")
        write_u32(pack, len(fb))
        write_u16(pack, len(base_vals))
        pack.extend(fb)
        pack.extend(flags)
        for v in base_vals:
            write_i128(pack, v)

    for dx, dy in offsets:
        write_i128(pack, dx)
        write_i128(pack, dy)

    for group in mode_groups:
        write_u16(pack, FAMILY_ID[group.family])
        write_u16(pack, group.rotation & 0xFFFF)
        write_u16(pack, group.skeleton_id)
        write_u16(pack, len(group.href_slot_base))
        write_u16(pack, len(group.style_slot_base))
        write_u16(pack, len(group.d_slot_base))
        write_u16(pack, len(group.href_map[0]))
        write_u16(pack, len(group.style_map[0]))
        write_u16(pack, len(group.d_map[0]))
        pack_u16_array(pack, group.href_slot_base)
        pack_u16_array(pack, group.style_slot_base)
        pack_u16_array(pack, group.d_slot_base)
        for trans_idx in range(len(MODE_TRANS_ORDER)):
            pack_u16_array(pack, group.href_map[trans_idx])
            pack_u16_array(pack, group.style_map[trans_idx])
            for tid, oid in group.d_map[trans_idx]:
                write_u16(pack, tid)
                write_u16(pack, oid)

    for family_record in scale_families:
        write_u16(pack, FAMILY_ID[family_record.family])
        write_u16(pack, family_record.skeleton_id)
        write_u16(pack, len(family_record.href_map[0]))
        write_u16(pack, len(family_record.style_map[0]))
        write_u16(pack, len(family_record.d_map[0]))
        pack_u16_array(pack, family_record.href_slot_base)
        pack_u16_array(pack, family_record.style_slot_base)
        pack_u16_array(pack, family_record.d_slot_base)
        for trans_idx in range(len(SCALE_TRANS_ORDER)):
            pack_u16_array(pack, family_record.href_map[trans_idx])
            pack_u16_array(pack, family_record.style_map[trans_idx])
            for tid, oid in family_record.d_map[trans_idx]:
                write_u16(pack, tid)
                write_u16(pack, oid)

    for kind, variant, raw in legacy_payloads:
        write_u16(pack, KIND_ID[kind])
        write_u16(pack, variant)
        write_u32(pack, len(raw))
        pack.extend(raw)

    stats = {
        "raw_len": len(pack),
        "skeleton_count": len(skeletons),
        "style_count": len(styles),
        "href_count": len(hrefs),
        "template_count": len(templates),
        "offset_count": len(offsets),
        "mode_group_count": len(mode_groups),
        "scale_family_count": len(scale_families),
        "legacy_count": len(legacy_payloads),
        "mode_max_href_slots": mode_max_href_slots,
        "mode_max_style_slots": mode_max_style_slots,
        "mode_max_d_slots": mode_max_d_slots,
        "mode_max_href_base": mode_max_href_base,
        "mode_max_style_base": mode_max_style_base,
        "mode_max_d_base": mode_max_d_base,
    }
    return bytes(pack), stats


def write_zig(out_path: str, xz_payload: bytes, stats: dict[str, int]) -> None:
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("// Auto-generated by scripts/generate_harmonious_majmin_scene_pack.py\n")
        f.write("// Source: tmp/harmoniousapp.net/majmin/*.svg\n\n")
        f.write(f"pub const PACK_RAW_LEN: usize = {stats['raw_len']};\n")
        f.write(f"pub const SKELETON_COUNT: usize = {stats['skeleton_count']};\n")
        f.write(f"pub const STYLE_COUNT: usize = {stats['style_count']};\n")
        f.write(f"pub const HREF_COUNT: usize = {stats['href_count']};\n")
        f.write(f"pub const TEMPLATE_COUNT: usize = {stats['template_count']};\n")
        f.write(f"pub const OFFSET_COUNT: usize = {stats['offset_count']};\n")
        f.write(f"pub const MODE_GROUP_COUNT: usize = {stats['mode_group_count']};\n")
        f.write(f"pub const SCALE_FAMILY_COUNT: usize = {stats['scale_family_count']};\n")
        f.write(f"pub const LEGACY_COUNT: usize = {stats['legacy_count']};\n")
        f.write("pub const MODE_TRANS_COUNT: usize = 13;\n")
        f.write("pub const SCALE_TRANS_COUNT: usize = 12;\n")
        f.write("pub const SCALE_HREF_SLOT_COUNT: usize = 153;\n")
        f.write("pub const SCALE_STYLE_SLOT_COUNT: usize = 324;\n")
        f.write("pub const SCALE_D_SLOT_COUNT: usize = 324;\n")
        f.write("pub const SCALE_HREF_BASE_COUNT: usize = 44;\n")
        f.write("pub const SCALE_STYLE_BASE_COUNT: usize = 4;\n")
        f.write("pub const SCALE_D_BASE_COUNT: usize = 248;\n")
        f.write(f"pub const MODE_MAX_HREF_SLOT_COUNT: usize = {stats['mode_max_href_slots']};\n")
        f.write(f"pub const MODE_MAX_STYLE_SLOT_COUNT: usize = {stats['mode_max_style_slots']};\n")
        f.write(f"pub const MODE_MAX_D_SLOT_COUNT: usize = {stats['mode_max_d_slots']};\n")
        f.write(f"pub const MODE_MAX_HREF_BASE_COUNT: usize = {stats['mode_max_href_base']};\n")
        f.write(f"pub const MODE_MAX_STYLE_BASE_COUNT: usize = {stats['mode_max_style_base']};\n")
        f.write(f"pub const MODE_MAX_D_BASE_COUNT: usize = {stats['mode_max_d_base']};\n")
        f.write("\n")
        f.write(f"pub const PACK_XZ_LEN: usize = {len(xz_payload)};\n")
        f.write("pub const PACK_XZ = [_]u8{\n")
        for i, b in enumerate(xz_payload):
            if i % 12 == 0:
                f.write("    ")
            f.write(f"0x{b:02x}, ")
            if i % 12 == 11:
                f.write("\n")
        if len(xz_payload) % 12 != 0:
            f.write("\n")
        f.write("};\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--majmin-dir", default="tmp/harmoniousapp.net/majmin")
    parser.add_argument("--out-zig", default="src/generated/harmonious_majmin_scene_pack_xz.zig")
    args = parser.parse_args()

    raw, stats = build_pack(args.majmin_dir)
    xz_payload = lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME)
    os.makedirs(os.path.dirname(args.out_zig), exist_ok=True)
    write_zig(args.out_zig, xz_payload, stats)

    print(
        f"Wrote {args.out_zig} | raw={len(raw)} bytes | xz={len(xz_payload)} bytes"
    )
    print(
        "counts:",
        f"skeletons={stats['skeleton_count']}",
        f"styles={stats['style_count']}",
        f"hrefs={stats['href_count']}",
        f"templates={stats['template_count']}",
        f"offsets={stats['offset_count']}",
        f"mode_groups={stats['mode_group_count']}",
        f"scale_families={stats['scale_family_count']}",
        f"legacy={stats['legacy_count']}",
    )
    print(
        "mode-max:",
        f"href_slots={stats['mode_max_href_slots']}",
        f"style_slots={stats['mode_max_style_slots']}",
        f"d_slots={stats['mode_max_d_slots']}",
        f"href_base={stats['mode_max_href_base']}",
        f"style_base={stats['mode_max_style_base']}",
        f"d_base={stats['mode_max_d_base']}",
    )


if __name__ == "__main__":
    main()
