#!/usr/bin/env python3

import json
import os

# Fixed GUID so we can safely find/update the same profile every time.
PROFILE_GUID = "8B6A6C58-7E18-4A32-B4C1-5F8A3A9E7F01"
PROFILE_NAME = "Rakhsh"
NERD_FONT = "0xProtoNFP-Regular 20"

def regex() -> str:
    #@ https://regex101.com/r/NSIXLe/1
    langs = ["cxx", "cpp", "cc", "c", "hpp", "hh", "h", "py", "sh", "lua", "tl", "txt"]
    _ = '|'.join(langs)
    return rf"^(?:\.{0,2}~/|/)|(?:\.{1,2}/)*(?:[A-Za-z0-9._-]+/)*[A-Za-z0-9._-]+\.(?:{_})(?::\d+(?::\d+)?)?"

def main():
    """
    This script does not touch `com.googlecode.iterm2.plist`.
    Instead, it manages a Dynamic Profile JSON file:

        ~/Library/Application Support/iTerm2/DynamicProfiles/rakhsh.json

    That iTerm2 sees a "Rakhsh" profile with:

        - a Smart Selection rule for file:line[:col]
        - Semantic History configured to run `rx --iterm \5 \1`.

    Sample product @ "$HOME/Library/Application Support/iTerm2/DynamicProfiles/rakhsh.json":
        ```json
        {
          "Profiles" : [
            {
              "Smart Selection Rules" : [
                {
                  "notes" : "Rakhsh: code file with optional :line:col",
                  "regex" : "...",
                  "precision" : "very_high"
                }
              ],
              "Use Non-ASCII Font" : true,
              "Non Ascii Font" : "Menlo-Regular 11",
              "Normal Font" : "0xProtoNFP-Regular 11",
              "Rewritable" : false,
              "Semantic History" : {
                "action" : "command",
                "text" : "/opt/github/rakhsh/bin/rx --iterm \\5 \\1"
              },
              "Guid" : "8B6A6C58-7E18-4A32-B4C1-5F8A3A9E7F01",
              "Name" : "Rakhsh",
              "Use Separate Colors for Light and Dark Mode" : true
            }
          ]
        }
        ```
    """

    script_dir = os.path.dirname(os.path.realpath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, os.pardir))
    rakhsh = os.path.join(repo_root, "bin", "rx")
    profile = {
        "Guid": PROFILE_GUID,
        "Name": PROFILE_NAME,
        "Normal Font": NERD_FONT,
        "Non Ascii Font": NERD_FONT,
        "Use Non-ASCII Font": True,
        "Smart Selection Rules": [
            {
                "notes": "Rakhsh: code file with optional :line:col",
                "precision": "very_high",
                "regex": regex(),
            }
        ],
        "Semantic History": {
            "action": "command",
            "text": f"{rakhsh} --iterm \\5 \\1",
        },
        "Use Separate Colors for Light and Dark Mode" : True,
    }
    data = {"Profiles": [profile]}

    home = os.path.expanduser("~")
    dyn_dir = os.path.join(home, "Library", "Application Support", "iTerm2", "DynamicProfiles")
    os.makedirs(dyn_dir, exist_ok=True)
    json_path = os.path.join(dyn_dir, "rakhsh.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)


if __name__ == "__main__":
    # Idempotent script that will create or update the Rakhsh dynamic profile,
    # without touching any other iTerm2 settings.
    main()
