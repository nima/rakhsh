#!/usr/bin/env bash
set -euo pipefail

PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
BACKUP="$PLIST.bak"
XML="$PLIST.xml"

if [[ ! -f "$PLIST" ]]; then
  echo "iTerm2 prefs not found at $PLIST" >&2
  exit 1
fi

cp "$PLIST" "$BACKUP"

# Work in XML so it's diffable / mergeable.
plutil -convert xml1 "$PLIST"
python3 libexec/it2integ.py "$PLIST"
cp "$PLIST" "$XML"
plutil -convert binary1 "$PLIST"
