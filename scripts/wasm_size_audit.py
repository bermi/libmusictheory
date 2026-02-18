#!/usr/bin/env python3
"""WASM size audit + guardrails.

Reports section sizes, reachable generated asset footprint from src/root.zig,
and optional budget checks to prevent regressions while migrating to
algorithmic rendering.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from typing import Dict, List, Set

SECTION_RE = re.compile(r"^\s*\d+\s+(\S+)\s+([0-9a-fA-F]+)\b")
IMPORT_RE = re.compile(r'@import\("([^"]+)"\)')


@dataclass(frozen=True)
class GenFile:
    path: pathlib.Path
    size: int


def find_llvm_objdump() -> str:
    candidates = [
        "llvm-objdump",
        "/opt/llvm-zig/bin/llvm-objdump",
        "/usr/bin/llvm-objdump",
    ]
    for cand in candidates:
        resolved = shutil.which(cand)
        if resolved:
            return resolved
        if pathlib.Path(cand).exists():
            return cand
    raise FileNotFoundError("llvm-objdump not found")


def parse_sections(wasm_path: pathlib.Path) -> Dict[str, int]:
    objdump = find_llvm_objdump()
    proc = subprocess.run(
        [objdump, "-h", str(wasm_path)],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    sections: Dict[str, int] = {}
    for line in proc.stdout.splitlines():
        m = SECTION_RE.match(line)
        if not m:
            continue
        name = m.group(1)
        size_hex = m.group(2)
        sections[name] = int(size_hex, 16)
    if not sections:
        raise RuntimeError("failed to parse wasm sections from llvm-objdump output")
    return sections


def resolve_import(base: pathlib.Path, import_str: str, src_root: pathlib.Path) -> pathlib.Path | None:
    if import_str in ("std", "builtin"):
        return None

    if import_str.startswith("."):
        target = (base.parent / import_str).resolve()
    else:
        target = (src_root / import_str).resolve()

    if target.suffix == "":
        target = target.with_suffix(".zig")

    return target if target.exists() else None


def collect_reachable_generated(src_root: pathlib.Path, root_file: pathlib.Path) -> List[GenFile]:
    seen: Set[pathlib.Path] = set()
    stack: List[pathlib.Path] = [root_file.resolve()]

    while stack:
        path = stack.pop()
        if path in seen or not path.exists():
            continue
        seen.add(path)

        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue

        for m in IMPORT_RE.finditer(text):
            target = resolve_import(path, m.group(1), src_root)
            if target is not None and target not in seen:
                stack.append(target)

    out: List[GenFile] = []
    gen_root = (src_root / "generated").resolve()
    for path in seen:
        try:
            path.relative_to(gen_root)
        except ValueError:
            continue
        out.append(GenFile(path=path, size=path.stat().st_size))

    out.sort(key=lambda item: item.size, reverse=True)
    return out


def is_coordinate_like(path: pathlib.Path) -> bool:
    name = path.name
    patterns = (
        "_x_lookup",
        "_y_lookup",
        "_by_index",
        "_profile_tuning",
        "_keysig_lines",
        "_nomod_names",
        "_layout_ulpshim",
        "_patches",
        "scale_mod_assets",
        "scale_nomod_assets",
    )
    return any(p in name for p in patterns)


def format_bytes(n: int) -> str:
    return f"{n:,}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit wasm size and generated-data footprint")
    parser.add_argument("--wasm", type=pathlib.Path, default=pathlib.Path("zig-out/wasm-demo/libmusictheory.wasm"))
    parser.add_argument("--src-root", type=pathlib.Path, default=pathlib.Path("src"))
    parser.add_argument("--root-zig", type=pathlib.Path, default=pathlib.Path("src/root.zig"))
    parser.add_argument("--top", type=int, default=12)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--max-wasm-bytes", type=int)
    parser.add_argument("--max-data-bytes", type=int)
    parser.add_argument("--max-reachable-generated-bytes", type=int)
    parser.add_argument("--max-coordinate-generated-bytes", type=int)
    args = parser.parse_args()

    repo_root = pathlib.Path.cwd().resolve()
    wasm_path = args.wasm.resolve()
    src_root = args.src_root.resolve()
    root_file = args.root_zig.resolve()

    if not wasm_path.exists():
        print(f"error: wasm file not found: {wasm_path}", file=sys.stderr)
        return 2

    sections = parse_sections(wasm_path)
    wasm_bytes = wasm_path.stat().st_size
    data_bytes = sections.get("DATA", 0)
    code_bytes = sections.get("CODE", 0)

    generated = collect_reachable_generated(src_root, root_file)
    generated_total = sum(item.size for item in generated)
    coord_files = [item for item in generated if is_coordinate_like(item.path)]
    coord_total = sum(item.size for item in coord_files)

    def display_path(path: pathlib.Path) -> str:
        try:
            return path.resolve().relative_to(repo_root).as_posix()
        except ValueError:
            return path.as_posix()

    result = {
        "wasm_bytes": wasm_bytes,
        "code_bytes": code_bytes,
        "data_bytes": data_bytes,
        "section_bytes": sections,
        "reachable_generated_bytes": generated_total,
        "reachable_generated_count": len(generated),
        "coordinate_generated_bytes": coord_total,
        "coordinate_generated_count": len(coord_files),
        "top_generated": [
            {
                "path": display_path(item.path),
                "size": item.size,
                "coordinate_like": is_coordinate_like(item.path),
            }
            for item in generated[: args.top]
        ],
    }

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print("WASM Size Audit")
        print(f"  wasm bytes: {format_bytes(wasm_bytes)}")
        print(f"  code bytes: {format_bytes(code_bytes)}")
        print(f"  data bytes: {format_bytes(data_bytes)}")
        print(
            "  reachable generated: "
            f"{len(generated)} files, {format_bytes(generated_total)} bytes"
        )
        print(
            "  coordinate-like generated: "
            f"{len(coord_files)} files, {format_bytes(coord_total)} bytes"
        )
        print("  top reachable generated files:")
        for item in generated[: args.top]:
            marker = " [coord]" if is_coordinate_like(item.path) else ""
            print(f"    - {display_path(item.path)} :: {format_bytes(item.size)}{marker}")

    errors: List[str] = []
    if args.max_wasm_bytes is not None and wasm_bytes > args.max_wasm_bytes:
        errors.append(
            f"wasm size {wasm_bytes} exceeds max {args.max_wasm_bytes}"
        )
    if args.max_data_bytes is not None and data_bytes > args.max_data_bytes:
        errors.append(
            f"wasm DATA section {data_bytes} exceeds max {args.max_data_bytes}"
        )
    if (
        args.max_reachable_generated_bytes is not None
        and generated_total > args.max_reachable_generated_bytes
    ):
        errors.append(
            "reachable generated size "
            f"{generated_total} exceeds max {args.max_reachable_generated_bytes}"
        )
    if (
        args.max_coordinate_generated_bytes is not None
        and coord_total > args.max_coordinate_generated_bytes
    ):
        errors.append(
            "coordinate-like generated size "
            f"{coord_total} exceeds max {args.max_coordinate_generated_bytes}"
        )

    if errors:
        for err in errors:
            print(f"error: {err}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
