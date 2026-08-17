#!/usr/bin/env bash
# The app fetches its change list from the URLs in AppURLs.releasesJSONSources.
# When every one of them is unreachable or serving something that will not
# decode, the update prompt shows no changes — which is how it read as broken
# with nothing in the app to blame.
#
# Passes when at least one source works, since the fallback exists precisely so
# a fresh release can ship before Pages has redeployed. Reports each one either
# way, because "the fallback is carrying it" is worth knowing before it is the
# only one left.
set -uo pipefail

SOURCES=(
  "https://doublej.github.io/consult-user-mcp/releases.json"
  "https://raw.githubusercontent.com/doublej/consult-user-mcp/main/docs/src/lib/data/releases.json"
)

ok=0
for url in "${SOURCES[@]}"; do
  body="$(mktemp)"
  if ! status="$(curl -sS -o "$body" -w '%{http_code}' --max-time 15 "$url" 2>/dev/null)"; then
    status="${status:-000}"
  fi
  if [ "$status" != "200" ]; then
    echo "  FAIL  http $status  $url"
    rm -f "$body"
    continue
  fi
  # The decode the app does. A 200 serving an HTML error page still fails here,
  # which is the case the app used to swallow.
  if python3 - "$body" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
rs = d["releases"]
assert rs, "no releases"
valid = {"added", "changed", "fixed", "removed"}
for r in rs:
    for k in ("version", "platform", "date", "changes"):
        assert k in r, f"{r.get('version')}: missing {k}"
    for c in r["changes"]:
        assert "text" in c, f"{r['version']}: change without text"
        assert c.get("type") in valid, f"{r['version']}: bad type {c.get('type')!r}"
assert any(r["platform"] == "macos" for r in rs), "no macos releases"
print(f"    {len(rs)} releases, newest {rs[0]['version']}")
PY
  then
    echo "  ok    $url"
    ok=$((ok + 1))
  else
    echo "  FAIL  decoded badly  $url"
  fi
  rm -f "$body"
done

if [ "$ok" -eq 0 ]; then
  echo "error: no change-list source works — the update prompt will show nothing" >&2
  exit 1
fi
echo "ok: $ok of ${#SOURCES[@]} change-list sources usable"
