import base64
import json
import os
import urllib.request

repo = os.environ["REPO"]
branch = os.environ["TARGET_BRANCH"]
token = os.environ["GH_TOKEN"]
path = ".github/workflows/gate2a-air-baseline.yml"
api = f"https://api.github.com/repos/{repo}/contents/{path}?ref={branch}"
headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}
req = urllib.request.Request(api, headers=headers)
with urllib.request.urlopen(req) as response:
    obj = json.load(response)
text = base64.b64decode(obj["content"]).decode("utf-8")
old = '''          SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
          if [ -z "$SDK_ROOT" ] || [ ! -d "$SDK_ROOT/platform-tools" ]; then
            echo "Android platform-tools unavailable on runtime-smoke runner" >&2
            exit 1
          fi
          find "$SDK_ROOT/platform-tools" -type f -print0 | sort -z | while IFS= read -r -d '' f; do
            rel="${f#"$SDK_ROOT/platform-tools/"}"
            bytes=$(wc -c < "$f" | tr -d ' ')
            sha=$(sha256sum "$f" | awk '{print $1}')
            printf '%s  %s  %s\\n' "$sha" "$bytes" "$rel"
          done > smoke-provenance/platform-tools-sha256-manifest.txt
          sha256sum smoke-provenance/platform-tools-sha256-manifest.txt > smoke-provenance/platform-tools-manifest.sha256
          adb version > smoke-provenance/adb-version.txt 2>&1
          sha256sum "$(command -v adb)" > smoke-provenance/adb-binary.sha256
'''
new = '''          SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
          if [ -z "$SDK_ROOT" ] || [ ! -d "$SDK_ROOT/platform-tools" ]; then
            echo "Android platform-tools unavailable on runtime-smoke runner" >&2
            exit 1
          fi
          ADB="$SDK_ROOT/platform-tools/adb"
          if [ ! -x "$ADB" ]; then
            echo "Android adb binary unavailable at expected SDK path: $ADB" >&2
            exit 1
          fi
          echo "$SDK_ROOT/platform-tools" >> "$GITHUB_PATH"
          find "$SDK_ROOT/platform-tools" -type f -print0 | sort -z | while IFS= read -r -d '' f; do
            rel="${f#"$SDK_ROOT/platform-tools/"}"
            bytes=$(wc -c < "$f" | tr -d ' ')
            sha=$(sha256sum "$f" | awk '{print $1}')
            printf '%s  %s  %s\\n' "$sha" "$bytes" "$rel"
          done > smoke-provenance/platform-tools-sha256-manifest.txt
          sha256sum smoke-provenance/platform-tools-sha256-manifest.txt > smoke-provenance/platform-tools-manifest.sha256
          "$ADB" version > smoke-provenance/adb-version.txt 2>&1
          sha256sum "$ADB" > smoke-provenance/adb-binary.sha256
'''
count = text.count(old)
if count != 1:
    raise SystemExit(f"exact patch fence mismatch: expected 1 occurrence, found {count}")
patched = text.replace(old, new, 1)
payload = json.dumps({
    "message": "Gate 2A r26: resolve runtime-smoke adb from exact SDK path",
    "content": base64.b64encode(patched.encode("utf-8")).decode("ascii"),
    "sha": obj["sha"],
    "branch": branch,
}).encode("utf-8")
req2 = urllib.request.Request(
    f"https://api.github.com/repos/{repo}/contents/{path}",
    data=payload,
    method="PUT",
    headers={**headers, "Content-Type": "application/json"},
)
with urllib.request.urlopen(req2) as response:
    result = json.load(response)
print("commit=" + result["commit"]["sha"])
print("blob=" + result["content"]["sha"])
