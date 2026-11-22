#!/usr/bin/env python3
"""Writes handcrafted level JSON files from compact row specs.
Run: python3 tools/author_levels.py   (then verify with the Godot solver tool)."""
import json, os, sys

LEVELS = {}

def L(n, name, world, tutorial, rows, par=0):
    LEVELS[n] = {"format": 1, "id": "level_%02d" % n, "name": name, "world": world,
                 "tutorial": tutorial, "par": par, "rows": [r.strip() for r in rows.strip().splitlines()]}

exec(open(os.path.join(os.path.dirname(__file__), "level_specs.txt")).read())

out = os.path.join(os.path.dirname(__file__), "..", "data", "levels")
os.makedirs(out, exist_ok=True)
pars = {}
if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
    pars = json.load(open(sys.argv[1]))
for n, d in sorted(LEVELS.items()):
    if d["id"] in pars:
        d["par"] = pars[d["id"]]
    with open(os.path.join(out, "level_%02d.json" % n), "w") as f:
        json.dump(d, f, indent=1)
        f.write("\n")
print("wrote", len(LEVELS), "levels")
