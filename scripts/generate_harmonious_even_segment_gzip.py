#!/usr/bin/env python3
"""Generate segmented gzip harmonious even compat assets."""

from __future__ import annotations

import argparse
import gzip
from pathlib import Path


LINE_ANCHOR = (
    b'  <line stroke-width="1" stroke="black" style="fill: transparent; stroke: #888; '
    b'stroke-width: 2" x1="0" y1="0" x2="0" y2="1233.2882874656677"/>'
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default="tmp/harmoniousapp.net", help="harmoniousapp root")
    parser.add_argument(
        "--out",
        default="src/generated/harmonious_even_segment_gzip.zig",
        help="output Zig module path",
    )
    return parser.parse_args()


def lcp(a: bytes, b: bytes) -> int:
    i = 0
    lim = min(len(a), len(b))
    while i < lim and a[i] == b[i]:
        i += 1
    return i


def zig_byte_array(name: str, payload: bytes) -> str:
    out = [f"pub const {name} = [_]u8{{\n"]
    for i in range(0, len(payload), 16):
        chunk = payload[i : i + 16]
        out.append("    " + ", ".join(f"0x{b:02x}" for b in chunk) + ",\n")
    out.append("};\n\n")
    return "".join(out)


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    even_dir = root / "even"
    out_path = Path(args.out)

    index = (even_dir / "index.svg").read_bytes()
    grad = (even_dir / "grad.svg").read_bytes()
    line = (even_dir / "line.svg").read_bytes()

    idx_pos = index.find(LINE_ANCHOR)
    grad_pos = grad.find(LINE_ANCHOR)
    line_pos = line.find(LINE_ANCHOR)
    if idx_pos < 0 or grad_pos < 0 or line_pos < 0:
        raise RuntimeError("line anchor not found in one or more even SVGs")

    compat_prefix = grad[:grad_pos]
    if line[:line_pos] != compat_prefix:
        raise RuntimeError("grad/line compat prefixes diverged")

    index_prefix = index[:idx_pos]

    index_suffix = index[idx_pos:]
    grad_suffix = grad[grad_pos:]
    line_suffix = line[line_pos:]

    common_len = min(
        lcp(index_suffix, grad_suffix),
        lcp(index_suffix, line_suffix),
        lcp(grad_suffix, line_suffix),
    )
    common_body = index_suffix[:common_len]

    index_tail = index_suffix[common_len:]
    grad_tail = grad_suffix[common_len:]
    line_tail = line_suffix[common_len:]

    if compat_prefix + common_body + grad_tail != grad:
        raise RuntimeError("grad reconstruction mismatch")
    if compat_prefix + common_body + line_tail != line:
        raise RuntimeError("line reconstruction mismatch")
    if index_prefix + common_body + index_tail != index:
        raise RuntimeError("index reconstruction mismatch")

    gz_parts = {
        "COMPAT_PREFIX_GZIP": gzip.compress(compat_prefix, compresslevel=9),
        "INDEX_PREFIX_GZIP": gzip.compress(index_prefix, compresslevel=9),
        "COMMON_BODY_GZIP": gzip.compress(common_body, compresslevel=9),
        "GRAD_TAIL_GZIP": gzip.compress(grad_tail, compresslevel=9),
        "LINE_TAIL_GZIP": gzip.compress(line_tail, compresslevel=9),
        "INDEX_TAIL_GZIP": gzip.compress(index_tail, compresslevel=9),
    }

    out = [
        "// Auto-generated segmented gzip payloads for harmonious even/*.svg exact assets.",
        "// DO NOT EDIT MANUALLY.",
        "",
    ]
    for key, payload in gz_parts.items():
        out.append(zig_byte_array(key, payload))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(out), encoding="utf-8")

    total = sum(len(payload) for payload in gz_parts.values())
    print(
        f"wrote {out_path} (segmented gzip bytes={total}, "
        f"compat={len(gz_parts['COMPAT_PREFIX_GZIP'])}, index_prefix={len(gz_parts['INDEX_PREFIX_GZIP'])}, "
        f"common={len(gz_parts['COMMON_BODY_GZIP'])}, grad={len(gz_parts['GRAD_TAIL_GZIP'])}, "
        f"line={len(gz_parts['LINE_TAIL_GZIP'])}, index_tail={len(gz_parts['INDEX_TAIL_GZIP'])})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
