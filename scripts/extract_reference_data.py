#!/usr/bin/env python3
"""Extract reference anchors from local harmoniousapp snapshots.

This script is intentionally lightweight: it collects a few stable counters and
known labels that can be used to refresh Zig test fixtures.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path("/Users/bermi/tmp/harmoniousapp.net/p")

SET_CLASSES_HTML = ROOT / "71" / "Set-Classes.html"
THE_GAME_HTML = ROOT / "69" / "The-Game.html"
CLUSTER_FREE_HTML = ROOT / "8b" / "Cluster-free.html"


def extract_set_class_anchors(html: str) -> dict[str, object]:
    forte_refs = sorted(set(re.findall(r"\b\d-\d{1,2}(?:z)?\b", html, flags=re.IGNORECASE)))
    return {
        "forte_ref_count": len(forte_refs),
        "contains_3_11": "3-11" in {f.upper() for f in forte_refs},
    }


def extract_int(html: str, pattern: str) -> int | None:
    m = re.search(pattern, html, flags=re.IGNORECASE)
    if not m:
        return None
    return int(m.group(1))


def main() -> None:
    payload: dict[str, object] = {"sources": {}}

    if SET_CLASSES_HTML.exists():
        html = SET_CLASSES_HTML.read_text(encoding="utf-8", errors="ignore")
        payload["sources"]["set_classes"] = extract_set_class_anchors(html)

    if CLUSTER_FREE_HTML.exists():
        html = CLUSTER_FREE_HTML.read_text(encoding="utf-8", errors="ignore")
        payload["sources"]["cluster_free"] = {
            "cluster_free_count": extract_int(html, r"cluster[- ]free[^0-9]{0,20}(\d+)"),
        }

    if THE_GAME_HTML.exists():
        html = THE_GAME_HTML.read_text(encoding="utf-8", errors="ignore")
        payload["sources"]["the_game"] = {
            "otc_count": extract_int(html, r"otc[^0-9]{0,20}(\d+)"),
            "mode_subset_count": extract_int(html, r"mode[^0-9]{0,20}(\d+)"),
        }

    print(json.dumps(payload, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
