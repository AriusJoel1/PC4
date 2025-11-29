#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# convertir ruta /c/... → C:/...
convert_path() {
  local p="$1"
  if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
    drive="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[2]}"
    echo "${drive}:/${rest}"
  else
    echo "$p"
  fi
}

REPORT_DIR="$ROOT_DIR/reports"
OUT="$REPORT_DIR/docker-results.json"

mkdir -p "$REPORT_DIR"

echo "[collect] Running open mode..."
"$SCRIPT_DIR/docker-run-open.sh"

echo "[collect] Running hardened mode..."
"$SCRIPT_DIR/docker-run-hardened.sh"

OPEN_JSON=$(convert_path "$REPORT_DIR/open.json")
HARDENED_JSON=$(convert_path "$REPORT_DIR/hardened.json")
OUT_JSON=$(convert_path "$OUT")

echo "[collect] Combining results into $OUT_JSON"

python <<EOF
import json, time

open_path = r"$OPEN_JSON"
hard_path = r"$HARDENED_JSON"
out_path = r"$OUT_JSON"

data = {"collected_at": int(time.time())}

with open(open_path, "r") as f:
    data["open"] = json.load(f)

with open(hard_path, "r") as f:
    data["hardened"] = json.load(f)

with open(out_path, "w") as f:
    json.dump(data, f, indent=2)

print("[collect] DONE ->", out_path)
EOF
