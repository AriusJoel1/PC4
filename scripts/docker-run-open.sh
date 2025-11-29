#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_TAG="project13:1.0.0"
CONTAINER_NAME="project13_open"
HOST_PORT=8000
CTR_PORT=8000
REPORT_DIR="$ROOT_DIR/reports"
OPEN_JSON="$REPORT_DIR/open.json"

mkdir -p "$REPORT_DIR"

echo "[open] Building image (tag: $IMAGE_TAG)..."
docker build -t "$IMAGE_TAG" -f "$ROOT_DIR/docker/Dockerfile" "$ROOT_DIR"

echo "[open] Removing old container if exists..."
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

echo "[open] Running container (open mode) mapping host:${HOST_PORT}->container:${CTR_PORT}..."
docker run -d --name "$CONTAINER_NAME" -p ${HOST_PORT}:${CTR_PORT} "$IMAGE_TAG" >/dev/null

# wait until /check responds or timeout
echo "[open] Waiting for service to be available on http://localhost:${HOST_PORT}/check ..."
MAX_WAIT=20
i=0
while [ $i -lt $MAX_WAIT ]; do
  if curl -sSf "http://localhost:${HOST_PORT}/check" -o "$OPEN_JSON"; then
    echo "[open] /check responded, saved -> $OPEN_JSON"
    break
  fi
  i=$((i+1))
  sleep 1
done

if [ $i -ge $MAX_WAIT ]; then
  echo "[open] Timeout: service did not respond in ${MAX_WAIT}s. Saving empty JSON."
  echo "{}" > "$OPEN_JSON"
fi
