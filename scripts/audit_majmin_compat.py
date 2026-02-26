#!/usr/bin/env python3
"""Audit harmonious majmin/* SVG structural invariants.

This script validates deterministic structural properties for:
  - tmp/harmoniousapp.net/majmin/modes,*.svg
  - tmp/harmoniousapp.net/majmin/scales,*.svg

The audit is a migration guardrail for future algorithmic majmin rendering.
"""

from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path
from typing import Dict


KIND_PREFIXES = ("modes", "scales")
VIEWBOX_SMALL = "0 0 300 360"
VIEWBOX_MEDIUM = "0 0 436 510"
VIEWBOX_LARGE = "0 0 708 510"

EXPECTED = {
    "modes": {
        "file_count": 366,
        "special_names": {"modes,-1,,-3,1", "modes,-1,,-3,2"},
        "transposition_counts": {
            "-1": 30,
            "0": 28,
            "1": 28,
            "2": 28,
            "3": 28,
            "4": 28,
            "5": 28,
            "6": 28,
            "7": 28,
            "8": 28,
            "9": 28,
            "10": 28,
            "11": 28,
        },
        "shape_counts": {"": 2, "dntri": 91, "hex": 91, "rhomb": 91, "uptri": 91},
        "rotation_counts": {"-3": 2, "0": 52, "1": 52, "3": 26, "4": 26, "7": 52, "8": 26, "9": 26, "10": 52, "11": 52},
        "viewbox_counts": {VIEWBOX_SMALL: 364, VIEWBOX_MEDIUM: 1, VIEWBOX_LARGE: 1},
        "path_count_by_shape": {
            "": {578: 1, 846: 1},
            "dntri": {362: 39, 364: 13, 370: 13, 372: 13, 374: 13},
            "hex": {362: 26, 364: 13, 370: 13, 372: 13, 374: 26},
            "rhomb": {362: 26, 364: 13, 370: 26, 372: 13, 374: 13},
            "uptri": {362: 39, 364: 13, 372: 13, 374: 26},
        },
        "anchor_count_by_shape": {
            "": {204: 1, 294: 1},
            "dntri": {115: 39, 121: 13, 139: 13, 145: 13, 151: 13},
            "hex": {115: 26, 121: 13, 139: 13, 145: 13, 151: 26},
            "rhomb": {115: 26, 121: 13, 139: 26, 145: 13, 151: 13},
            "uptri": {115: 39, 121: 13, 145: 13, 151: 26},
        },
    },
    "scales": {
        "file_count": 50,
        "special_names": {"scales,-1,,0,1", "scales,-1,,0,2"},
        "transposition_counts": {
            "-1": 2,
            "0": 4,
            "1": 4,
            "2": 4,
            "3": 4,
            "4": 4,
            "5": 4,
            "6": 4,
            "7": 4,
            "8": 4,
            "9": 4,
            "10": 4,
            "11": 4,
        },
        "shape_counts": {"": 2, "dntri": 12, "hex": 12, "rhomb": 12, "uptri": 12},
        "rotation_counts": {"0": 6, "1": 4, "2": 4, "3": 4, "4": 4, "5": 4, "6": 4, "7": 4, "8": 4, "9": 4, "10": 4, "11": 4},
        "viewbox_counts": {VIEWBOX_SMALL: 48, VIEWBOX_MEDIUM: 1, VIEWBOX_LARGE: 1},
        "path_count_by_shape": {
            "": {510: 1, 748: 1},
            "dntri": {324: 12},
            "hex": {324: 12},
            "rhomb": {324: 12},
            "uptri": {324: 12},
        },
        "anchor_count_by_shape": {
            "": {240: 1, 352: 1},
            "dntri": {153: 12},
            "hex": {153: 12},
            "rhomb": {153: 12},
            "uptri": {153: 12},
        },
    },
}

VIEWBOX_RE = re.compile(r'viewBox="([^"]+)"')
PATH_RE = re.compile(r"<path\b")
ANCHOR_RE = re.compile(r"<a\b")
CIRCLE_RE = re.compile(r"<circle\b")
TEXT_RE = re.compile(r"<text\b")
PATH_STYLE_RE = re.compile(r'<path[^>]* style="')
PATH_D_RE = re.compile(r'<path[^>]* d="')


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


def parse_name(svg_path: Path) -> tuple[str, str, str, str, str | None]:
    parts = svg_path.stem.split(",")
    if len(parts) == 4:
        kind, transposition, shape, rotation = parts
        variant = None
    elif len(parts) == 5:
        kind, transposition, shape, rotation, variant = parts
    else:
        raise AssertionError(f"{svg_path.name}: invalid token count ({len(parts)})")
    return kind, transposition, shape, rotation, variant


def verify_special_case(kind: str, transposition: str, shape: str, rotation: str, variant: str | None, file_name: str) -> None:
    if shape != "":
        if variant is not None:
            raise AssertionError(f"{file_name}: non-empty shape cannot include variant")
        return

    if variant is None:
        raise AssertionError(f"{file_name}: empty-shape entries must include variant token")

    if transposition != "-1":
        raise AssertionError(f"{file_name}: empty-shape entries must use transposition=-1")

    if variant not in {"1", "2"}:
        raise AssertionError(f"{file_name}: invalid variant token '{variant}'")

    expected_rotation = "-3" if kind == "modes" else "0"
    if rotation != expected_rotation:
        raise AssertionError(
            f"{file_name}: empty-shape {kind} entry must use rotation={expected_rotation}, got {rotation}"
        )


def audit_kind(majmin_dir: Path, kind: str) -> Dict[str, object]:
    expected = EXPECTED[kind]
    files = sorted(majmin_dir.glob(f"{kind},*.svg"))
    assert_equal(f"{kind}: file count", len(files), expected["file_count"])

    transposition_counts: collections.Counter[str] = collections.Counter()
    shape_counts: collections.Counter[str] = collections.Counter()
    rotation_counts: collections.Counter[str] = collections.Counter()
    viewbox_counts: collections.Counter[str] = collections.Counter()
    path_count_by_shape: Dict[str, collections.Counter[int]] = collections.defaultdict(collections.Counter)
    anchor_count_by_shape: Dict[str, collections.Counter[int]] = collections.defaultdict(collections.Counter)
    special_names: set[str] = set()

    circle_total = 0
    text_total = 0

    for svg_path in files:
        file_name = svg_path.name
        stem_name = svg_path.stem
        parsed_kind, transposition, shape, rotation, variant = parse_name(svg_path)
        assert_equal(f"{file_name}: kind prefix", parsed_kind, kind)

        verify_special_case(kind, transposition, shape, rotation, variant, file_name)

        if shape == "":
            special_names.add(stem_name)
        else:
            if variant is not None:
                raise AssertionError(f"{file_name}: non-empty shape cannot include variant")

        transposition_counts[transposition] += 1
        shape_counts[shape] += 1
        rotation_counts[rotation] += 1

        svg_text = svg_path.read_text(encoding="utf-8")

        viewbox_match = VIEWBOX_RE.search(svg_text)
        if not viewbox_match:
            raise AssertionError(f"{file_name}: missing viewBox attribute")
        viewbox = viewbox_match.group(1)
        viewbox_counts[viewbox] += 1

        path_count = len(PATH_RE.findall(svg_text))
        anchor_count = len(ANCHOR_RE.findall(svg_text))
        path_style_count = len(PATH_STYLE_RE.findall(svg_text))
        path_d_count = len(PATH_D_RE.findall(svg_text))
        circle_count = len(CIRCLE_RE.findall(svg_text))
        text_count = len(TEXT_RE.findall(svg_text))

        assert_equal(f"{file_name}: path-style count", path_style_count, path_count)
        assert_equal(f"{file_name}: path-d count", path_d_count, path_count)

        path_count_by_shape[shape][path_count] += 1
        anchor_count_by_shape[shape][anchor_count] += 1
        circle_total += circle_count
        text_total += text_count

    assert_equal(f"{kind}: special file set", special_names, expected["special_names"])
    assert_equal(f"{kind}: transposition counts", dict(transposition_counts), expected["transposition_counts"])
    assert_equal(f"{kind}: shape counts", dict(shape_counts), expected["shape_counts"])
    assert_equal(f"{kind}: rotation counts", dict(rotation_counts), expected["rotation_counts"])
    assert_equal(f"{kind}: viewBox counts", dict(viewbox_counts), expected["viewbox_counts"])

    normalized_paths = {shape: dict(counter) for shape, counter in path_count_by_shape.items()}
    normalized_anchors = {shape: dict(counter) for shape, counter in anchor_count_by_shape.items()}

    assert_equal(f"{kind}: path-count by shape", normalized_paths, expected["path_count_by_shape"])
    assert_equal(f"{kind}: anchor-count by shape", normalized_anchors, expected["anchor_count_by_shape"])
    assert_equal(f"{kind}: total circle tags", circle_total, 0)
    assert_equal(f"{kind}: total text tags", text_total, 0)

    return {
        "kind": kind,
        "files": len(files),
        "special_names": sorted(special_names),
        "transposition_counts": dict(sorted(transposition_counts.items(), key=lambda kv: int(kv[0]))),
        "shape_counts": dict(shape_counts),
        "rotation_counts": dict(sorted(rotation_counts.items(), key=lambda kv: int(kv[0]))),
        "viewbox_counts": dict(viewbox_counts),
        "path_count_by_shape": {shape: dict(sorted(counter.items())) for shape, counter in normalized_paths.items()},
        "anchor_count_by_shape": {shape: dict(sorted(counter.items())) for shape, counter in normalized_anchors.items()},
        "circle_tags": circle_total,
        "text_tags": text_total,
    }


def normalize_json_value(value):
    if isinstance(value, dict):
        return {str(k): normalize_json_value(v) for k, v in value.items()}
    if isinstance(value, set):
        return sorted(normalize_json_value(v) for v in value)
    if isinstance(value, (list, tuple)):
        return [normalize_json_value(v) for v in value]
    return value


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    majmin_dir = root / "majmin"
    if not majmin_dir.is_dir():
        raise FileNotFoundError(f"missing majmin directory: {majmin_dir}")

    report = {
        "root": str(root),
        "majmin_dir": str(majmin_dir),
        "kinds": [audit_kind(majmin_dir, kind) for kind in KIND_PREFIXES],
        "invariants": normalize_json_value(EXPECTED),
    }

    if args.json:
        print(json.dumps(report, separators=(",", ":"), sort_keys=True))
    else:
        print(json.dumps(report, indent=2, sort_keys=True))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
