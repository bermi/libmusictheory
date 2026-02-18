#!/usr/bin/env python3
"""
Generate compact harmonious majmin compatibility payload.

Input:
  tmp/harmoniousapp.net/majmin/*.svg

Output:
  src/generated/harmonious_majmin_compat_xz.zig
"""

from __future__ import annotations

import argparse
import glob
import lzma
import os
import re
import struct
from dataclasses import dataclass

SCALE = 10**17

TAG_RE = re.compile(r"<(/?)([a-zA-Z]+)([^>]*)>")
ATTR_RE = re.compile(r'([a-zA-Z_:][\w:.-]*)="([^"]*)"')
NUM_RE = re.compile(r"[+-]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?")

# Marker bytes embedded directly in skeleton/template strings.
MARKER_HREF = "\x1d"
MARKER_STYLE = "\x1e"
MARKER_D = "\x1f"
MARKER_NUM = "\x01"

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
class FileRecord:
    skeleton_id: int
    href_ids: list[int]
    style_ids: list[int]
    d_refs: list[tuple[int, int]]


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


def tokenize_path(path_d: str) -> list[Token]:
    out: list[Token] = []
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
    first_pair: list[int] = []
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

    parts: list[tuple[str, str | int]] = []
    bases: list[int] = []
    flags: list[int] = []

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

        # Number token.
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

    fmt_parts: list[str] = []
    for kind, payload in parts:
        if kind == "lit":
            fmt_parts.append(payload)  # type: ignore[arg-type]
        else:
            fmt_parts.append(MARKER_NUM)
    fmt = "".join(fmt_parts)

    key = (fmt, tuple(bases), bytes(flags))
    return key, (dx, dy)


def parse_file(svg_text: str) -> tuple[str, list[str], list[str], list[str]]:
    pos = 0
    out_parts: list[str] = []
    href_values: list[str] = []
    style_values: list[str] = []
    d_values: list[str] = []

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


def intern(intern_map: dict, arr: list, value):
    existing = intern_map.get(value)
    if existing is not None:
        return existing
    idx = len(arr)
    intern_map[value] = idx
    arr.append(value)
    return idx


def write_u16(buf: bytearray, value: int):
    buf.extend(struct.pack("<H", value))


def write_u32(buf: bytearray, value: int):
    buf.extend(struct.pack("<I", value))


def write_i128(buf: bytearray, value: int):
    buf.extend(int(value).to_bytes(16, byteorder="little", signed=True))


def collect_names(majmin_dir: str, prefix: str) -> list[str]:
    out = []
    for path in glob.glob(os.path.join(majmin_dir, "*.svg")):
        name = os.path.basename(path)
        if name.startswith(prefix):
            out.append(name)
    return sorted(set(out))


def generate_pack(majmin_dir: str) -> tuple[bytes, dict[str, int]]:
    mode_names = collect_names(majmin_dir, "modes,")
    scale_names = collect_names(majmin_dir, "scales,")

    skeleton_map: dict[str, int] = {}
    style_map: dict[str, int] = {}
    href_map: dict[str, int] = {}
    template_map: dict[tuple[str, tuple[int, ...], bytes], int] = {}
    offset_map: dict[tuple[int, int], int] = {}

    skeletons: list[str] = []
    styles: list[str] = []
    hrefs: list[str] = []
    templates: list[tuple[str, tuple[int, ...], bytes]] = []
    offsets: list[tuple[int, int]] = []
    records: list[FileRecord] = []

    # Deterministic ordering aligned with harmonious_manifest generation.
    ordered = [(True, n) for n in mode_names] + [(False, n) for n in scale_names]

    for _is_mode, name in ordered:
        path = os.path.join(majmin_dir, name)
        svg_text = open(path, "r", encoding="utf-8").read()
        skeleton, href_vals, style_vals, d_vals = parse_file(svg_text)

        sid = intern(skeleton_map, skeletons, skeleton)
        href_ids = [intern(href_map, hrefs, h) for h in href_vals]
        style_ids = [intern(style_map, styles, s) for s in style_vals]

        d_refs: list[tuple[int, int]] = []
        for d in d_vals:
            tpl_key, off = make_template(d)
            tid = intern(template_map, templates, tpl_key)
            oid = intern(offset_map, offsets, off)
            d_refs.append((tid, oid))

        records.append(
            FileRecord(
                skeleton_id=sid,
                href_ids=href_ids,
                style_ids=style_ids,
                d_refs=d_refs,
            )
        )

    # Binary pack.
    pack = bytearray()
    pack.extend(b"MJMN2\x00\x00\x00")

    write_u32(pack, len(skeletons))
    write_u32(pack, len(styles))
    write_u32(pack, len(hrefs))
    write_u32(pack, len(templates))
    write_u32(pack, len(offsets))
    write_u32(pack, len(records))
    write_u32(pack, len(mode_names))
    write_u32(pack, len(scale_names))

    # Skeleton strings (u32 len + bytes)
    for s in skeletons:
        b = s.encode("utf-8", "surrogatepass")
        write_u32(pack, len(b))
        pack.extend(b)

    # Style strings (u16 len + bytes)
    for s in styles:
        b = s.encode("utf-8")
        write_u16(pack, len(b))
        pack.extend(b)

    # Href strings (u16 len + bytes)
    for h in hrefs:
        b = h.encode("utf-8")
        write_u16(pack, len(b))
        pack.extend(b)

    # Templates: fmt_len(u32), num_count(u16), fmt_bytes, flags[num_count], base[i128*num_count]
    for fmt, base_vals, flags in templates:
        fb = fmt.encode("utf-8", "surrogatepass")
        num_count = len(base_vals)
        write_u32(pack, len(fb))
        write_u16(pack, num_count)
        pack.extend(fb)
        pack.extend(flags)
        for v in base_vals:
            write_i128(pack, v)

    # Offsets: i128 dx, i128 dy
    for dx, dy in offsets:
        write_i128(pack, dx)
        write_i128(pack, dy)

    # Per-file records:
    # skeleton_id(u32), href_count/style_count/d_count(u16 each), href_ids[u16*], style_ids[u16*], d_refs[(u16 tid,u16 oid)*]
    for rec in records:
        write_u32(pack, rec.skeleton_id)
        write_u16(pack, len(rec.href_ids))
        write_u16(pack, len(rec.style_ids))
        write_u16(pack, len(rec.d_refs))
        for x in rec.href_ids:
            write_u16(pack, x)
        for x in rec.style_ids:
            write_u16(pack, x)
        for tid, oid in rec.d_refs:
            write_u16(pack, tid)
            write_u16(pack, oid)

    raw = bytes(pack)
    stats = {
        "raw_len": len(raw),
        "skeleton_count": len(skeletons),
        "style_count": len(styles),
        "href_count": len(hrefs),
        "template_count": len(templates),
        "offset_count": len(offsets),
        "file_count": len(records),
        "mode_count": len(mode_names),
        "scale_count": len(scale_names),
    }
    return raw, stats


def write_zig(out_path: str, raw: bytes, xz_payload: bytes, stats: dict[str, int]):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("// Auto-generated by scripts/generate_harmonious_majmin_compat.py\n")
        f.write("// Source: tmp/harmoniousapp.net/majmin/*.svg\n\n")
        f.write(f"pub const PACK_RAW_LEN: usize = {stats['raw_len']};\n")
        f.write(f"pub const SKELETON_COUNT: usize = {stats['skeleton_count']};\n")
        f.write(f"pub const STYLE_COUNT: usize = {stats['style_count']};\n")
        f.write(f"pub const HREF_COUNT: usize = {stats['href_count']};\n")
        f.write(f"pub const TEMPLATE_COUNT: usize = {stats['template_count']};\n")
        f.write(f"pub const OFFSET_COUNT: usize = {stats['offset_count']};\n")
        f.write(f"pub const FILE_COUNT: usize = {stats['file_count']};\n")
        f.write(f"pub const MODE_COUNT: usize = {stats['mode_count']};\n")
        f.write(f"pub const SCALE_COUNT: usize = {stats['scale_count']};\n\n")
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--majmin-dir", default="tmp/harmoniousapp.net/majmin")
    parser.add_argument(
        "--out-zig", default="src/generated/harmonious_majmin_compat_xz.zig"
    )
    args = parser.parse_args()

    raw, stats = generate_pack(args.majmin_dir)
    xz_payload = lzma.compress(
        raw,
        format=lzma.FORMAT_XZ,
        preset=9 | lzma.PRESET_EXTREME,
    )
    os.makedirs(os.path.dirname(args.out_zig), exist_ok=True)
    write_zig(args.out_zig, raw, xz_payload, stats)

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
        f"files={stats['file_count']}",
        f"modes={stats['mode_count']}",
        f"scales={stats['scale_count']}",
    )


if __name__ == "__main__":
    main()

