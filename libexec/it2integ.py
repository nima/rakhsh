#!/usr/bin/env python3

import os, sys, plistlib

plist_path = sys.argv[1]
script_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
repo_root = os.path.abspath(os.path.join(script_dir, os.pardir))
rakhsh = os.path.join(repo_root, "bin", "rx")

with open(plist_path, "rb") as f:
    data = plistlib.load(f)

default_guid = data.get("Default Bookmark Guid")
if not default_guid:
    raise SystemExit("No Default Bookmark Guid in plist")

bookmarks = data.get("New Bookmarks", [])
target = None
for prof in bookmarks:
    if prof.get("Guid") == default_guid:
        target = prof
        break
if target is None:
    raise SystemExit("Default profile not found in New Bookmarks")

rules = target.setdefault("Smart Selection Rules", [])

regex = (
    r"(\~?/?[[:alnum:]._-]+(/[[:alnum:]._-]+)*\.(c|cc|cpp|cxx|h|hpp|hh|py|sh|lua|tl|txt)(:[0-9]+(:[0-9]+)?)?)"
)

for r in rules:
    if r.get("regex") == regex:
        break
else:
    rules.insert(0, {
        "notes": "Rakhsh: code file with optional :line:col",
        "precision": "very_high",
        "regex": regex,
    })

sem = target.setdefault("Semantic History", {})
text = sem.get("text") or ""
cmd = f"{rakhsh} \\1"
if cmd not in text:
    sem["text"] = text + ("\n" if text else "") + cmd

with open(plist_path, "wb") as f:
    plistlib.dump(data, f)
