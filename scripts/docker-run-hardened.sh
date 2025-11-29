#!/usr/bin/env bash
set -euo pipefail

# Script hardened: detecta plataforma y aplica la variante correcta.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_TAG="project13:1.0.0"
CONTAINER_NAME="project13_hardened"
HOST_PORT=8001
CTR_PORT=8000
REPORT_DIR="$ROOT_DIR/reports"
HARD_JSON="$REPORT_DIR/hardened.json"
HARD_LOGS="$REPORT_DIR/hardened_logs.txt"

mkdir -p "$REPORT_DIR"

echo "[hardened] Building image (tag: $IMAGE_TAG)..."
docker build -t "$IMAGE_TAG" -f "$ROOT_DIR/docker/Dockerfile" "$ROOT_DIR"

echo "[hardened] Removing old container if exists..."
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# Detect platform (uname)
UNAME="$(uname -s 2>/dev/null || echo Unknown)"
echo "[hardened] Detected platform: $UNAME"

# Default flags (safe hardened)
COMMON_FLAGS=(--name "$CONTAINER_NAME" --cap-drop=ALL --security-opt no-new-privileges -p ${HOST_PORT}:${CTR_PORT})

# On Windows (MSYS/MINGW/CYGWIN) we avoid --read-only because Docker Desktop + Windows may break runtime writes.
case "$UNAME" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    echo "[hardened] Running Windows-friendly hardened mode (no --read-only)."
    docker run -d "${COMMON_FLAGS[@]}" "$IMAGE_TAG" >/dev/null
    ;;
  *)
    # Linux / WSL2 / macOS: we attempt full hardening using --read-only + tmpfs for writable dirs.
    echo "[hardened] Running full-hardened mode with --read-only + tmpfs (Linux/WSL2/macOS)."
    docker run -d \
      --read-only \
      --tmpfs /tmp:rw,noexec,nosuid,size=64m \
      --tmpfs /run:rw,noexec,nosuid,size=16m \
      --tmpfs /var:rw,noexec,nosuid,size=64m \
      "${COMMON_FLAGS[@]}" \
      "$IMAGE_TAG" >/dev/null
    ;;
esac

# wait for service
echo "[hardened] Waiting for service to be available on http://localhost:${HOST_PORT}/check ..."
MAX_WAIT=20
i=0
while [ $i -lt $MAX_WAIT ]; do
  if curl -sSf "http://localhost:${HOST_PORT}/check" -o "$HARD_JSON"; then
    echo "[hardened] /check responded, saved -> $HARD_JSON"
    break
  fi
  i=$((i+1))
  sleep 1
done

if [ $i -ge $MAX_WAIT ]; then
  echo "[hardened] Timeout: service did not respond in ${MAX_WAIT}s. Saving empty JSON."
  echo "{}" > "$HARD_JSON"
fi

# Collect logs (last 5s to keep small)
docker logs "$CONTAINER_NAME" --since 1s > "$HARD_LOGS" 2>/dev/null || docker logs "$CONTAINER_NAME" > "$HARD_LOGS" 2>/dev/null || true
echo "[hardened] Collected logs -> $HARD_LOGS"
