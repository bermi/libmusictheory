#!/usr/bin/env python3
"""Audit harmonious even/* SVG structural invariants.

This script validates the reverse-engineered model assumptions for:
  - tmp/harmoniousapp.net/even/index.svg
  - tmp/harmoniousapp.net/even/grad.svg
  - tmp/harmoniousapp.net/even/line.svg
"""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path
from typing import Dict, List, Sequence, Tuple


FILES = ("index.svg", "grad.svg", "line.svg")

EXPECTED_VISIBLE_COUNT = 194
EXPECTED_HIDDEN_COUNT = 194
EXPECTED_LINE_COUNT = 7
EXPECTED_TRIANGLE_COUNT = 78
EXPECTED_CIRCLE_MARKER_COUNT = 116
EXPECTED_HIDDEN_BLACK_COUNT = 6
EXPECTED_HIDDEN_TRANSPARENT_COUNT = 188
EXPECTED_RAY_COUNTS = [12, 29, 38, 36, 38, 29, 12]

EXPECTED_PAIRWISE = {
    ("grad.svg", "line.svg"): {
        "lcp": 116436,
        "lcsuf": 8,
        "unique_a": 1117,
        "unique_b": 10038,
    },
    ("grad.svg", "index.svg"): {
        "lcp": 721,
        "lcsuf": 15,
        "unique_a": 116825,
        "unique_b": 166984,
    },
    ("index.svg", "line.svg"): {
        "lcp": 721,
        "lcsuf": 8,
        "unique_a": 166991,
        "unique_b": 125753,
    },
}

LINE_RE = re.compile(r'<line [^>]*x2="([^"]+)" y2="([^"]+)"/>')
VISIBLE_RE = re.compile(
    r'<circle cx="([^"]+)" cy="([^"]+)" r="2" style="stroke: black; stroke-width: 3"/>'
)
HIDDEN_RE = re.compile(
    r'<circle cx="([^"]+)" cy="([^"]+)" r="2" style="fill: (transparent|black); stroke: black; stroke-width: 0"/>'
)
TRIANGLE_RE = re.compile(
    r'<path d="M0,80 L100,80 L50,-6z" style="fill: #eee; stroke: red; stroke-width: (8|9)"/>'
)
CIRCLE_MARKER_RE = re.compile(
    r'<circle cx="50\.00" cy="50\.00" r="45" style="fill: gray; stroke: black; stroke-width: (8|9)"/>'
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        default="tmp/harmoniousapp.net",
        help="Reference root path containing even/*.svg (default: tmp/harmoniousapp.net)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print compact JSON only.",
    )
    return parser.parse_args()


def lcp(a: str, b: str) -> int:
    i = 0
    lim = min(len(a), len(b))
    while i < lim and a[i] == b[i]:
        i += 1
    return i


def lcsuf(a: str, b: str) -> int:
    i = 0
    la = len(a)
    lb = len(b)
    while i < la and i < lb and a[la - 1 - i] == b[lb - 1 - i]:
        i += 1
    return i


def angle_deg(x: float, y: float) -> float:
    value = math.degrees(math.atan2(y, x))
    if value < 0.0:
        value += 360.0
    return value


def nearest_angle_index(angles: Sequence[float], candidate: float) -> int:
    return min(range(len(angles)), key=lambda idx: abs(candidate - angles[idx]))


def compute_ray_counts(svg: str) -> Tuple[List[int], List[float]]:
    lines = [(float(x2), float(y2)) for x2, y2 in LINE_RE.findall(svg)]
    line_angles = [angle_deg(x2, y2) for (x2, y2) in lines]

    visible_points = [(float(x), float(y)) for x, y in VISIBLE_RE.findall(svg)]
    assigned: List[int | None] = []
    for x, y in visible_points:
        if abs(x) < 1e-12 and abs(y) < 1e-12:
            assigned.append(None)
            continue
        assigned.append(nearest_angle_index(line_angles, angle_deg(x, y)))

    counts = [0] * len(line_angles)
    for i, idx in enumerate(assigned):
        if idx is None:
            j = i + 1
            while j < len(assigned) and assigned[j] is None:
                j += 1
            idx = assigned[j] if j < len(assigned) else 0
        counts[int(idx)] += 1

    return counts, line_angles


def audit_one(name: str, svg: str) -> Dict[str, object]:
    visible_count = len(VISIBLE_RE.findall(svg))
    hidden = HIDDEN_RE.findall(svg)
    hidden_count = len(hidden)
    hidden_black = sum(1 for _x, _y, fill in hidden if fill == "black")
    hidden_transparent = sum(1 for _x, _y, fill in hidden if fill == "transparent")
    marker_triangles = len(TRIANGLE_RE.findall(svg))
    marker_circles = len(CIRCLE_MARKER_RE.findall(svg))
    line_count = len(LINE_RE.findall(svg))
    ray_counts, line_angles = compute_ray_counts(svg)

    return {
        "file": name,
        "bytes": len(svg.encode("utf-8")),
        "visible_circles": visible_count,
        "hidden_circles": hidden_count,
        "hidden_black": hidden_black,
        "hidden_transparent": hidden_transparent,
        "marker_triangles": marker_triangles,
        "marker_circles": marker_circles,
        "line_count": line_count,
        "ray_counts": ray_counts,
        "line_angles_deg": line_angles,
    }


def assert_equal(label: str, got, expected) -> None:
    if got != expected:
        raise AssertionError(f"{label}: expected {expected}, got {got}")


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    even_dir = root / "even"

    missing = [name for name in FILES if not (even_dir / name).is_file()]
    if missing:
        raise FileNotFoundError(f"missing even SVG references: {missing} under {even_dir}")

    svgs: Dict[str, str] = {name: (even_dir / name).read_text(encoding="utf-8") for name in FILES}
    per_file = [audit_one(name, svgs[name]) for name in FILES]

    for entry in per_file:
        name = str(entry["file"])
        assert_equal(f"{name}: visible circles", entry["visible_circles"], EXPECTED_VISIBLE_COUNT)
        assert_equal(f"{name}: hidden circles", entry["hidden_circles"], EXPECTED_HIDDEN_COUNT)
        assert_equal(f"{name}: hidden black", entry["hidden_black"], EXPECTED_HIDDEN_BLACK_COUNT)
        assert_equal(
            f"{name}: hidden transparent", entry["hidden_transparent"], EXPECTED_HIDDEN_TRANSPARENT_COUNT
        )
        assert_equal(f"{name}: marker triangles", entry["marker_triangles"], EXPECTED_TRIANGLE_COUNT)
        assert_equal(f"{name}: marker circles", entry["marker_circles"], EXPECTED_CIRCLE_MARKER_COUNT)
        assert_equal(f"{name}: line count", entry["line_count"], EXPECTED_LINE_COUNT)
        assert_equal(f"{name}: ray counts", entry["ray_counts"], EXPECTED_RAY_COUNTS)

    pairwise: Dict[str, Dict[str, int]] = {}
    for (a_name, b_name), expected in EXPECTED_PAIRWISE.items():
        a = svgs[a_name]
        b = svgs[b_name]
        pref = lcp(a, b)
        suf = lcsuf(a, b)
        metrics = {
            "lcp": pref,
            "lcsuf": suf,
            "unique_a": len(a) - pref - suf,
            "unique_b": len(b) - pref - suf,
        }
        pairwise[f"{a_name}::{b_name}"] = metrics
        for key, expected_value in expected.items():
            assert_equal(f"{a_name} vs {b_name}: {key}", metrics[key], expected_value)

    report = {
        "root": str(root),
        "files": per_file,
        "pairwise": pairwise,
        "invariants": {
            "visible_circles": EXPECTED_VISIBLE_COUNT,
            "hidden_circles": EXPECTED_HIDDEN_COUNT,
            "line_count": EXPECTED_LINE_COUNT,
            "marker_triangles": EXPECTED_TRIANGLE_COUNT,
            "marker_circles": EXPECTED_CIRCLE_MARKER_COUNT,
            "hidden_black": EXPECTED_HIDDEN_BLACK_COUNT,
            "hidden_transparent": EXPECTED_HIDDEN_TRANSPARENT_COUNT,
            "ray_counts": EXPECTED_RAY_COUNTS,
        },
    }

    if args.json:
        print(json.dumps(report, separators=(",", ":"), sort_keys=True))
    else:
        print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
