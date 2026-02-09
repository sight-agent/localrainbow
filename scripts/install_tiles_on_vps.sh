#!/usr/bin/env bash
set -euo pipefail

# Install tiles archive into the docker volume on the VPS.
# Usage:
#   ./scripts/install_tiles_on_vps.sh /root/valhalla-italy.tar.zst

ARCHIVE_PATH="${1:-}"
if [ -z "$ARCHIVE_PATH" ] || [ ! -f "$ARCHIVE_PATH" ]; then
  echo "Usage: $0 /path/to/valhalla-italy.tar.{zst|gz|tar}" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VOL_NAME="localrainbow_valhalla_tiles"

echo "Stopping valhalla container (if running)..."
docker compose stop valhalla || true

echo "Extracting archive into docker volume $VOL_NAME ..."
# We extract into /data with correct paths: /data/tiles and /data/valhalla.json
# Use alpine and install zstd if needed.

docker run --rm -v ${VOL_NAME}:/data -v "$(dirname "$ARCHIVE_PATH")":/host alpine:3.19 sh -lc "\
  set -e; \
  apk add --no-cache tar zstd >/dev/null 2>&1 || true; \
  cd /data; \
  rm -rf tiles; \
  case \"/host/$(basename "$ARCHIVE_PATH")\" in \
    *.tar.zst) zstd -d -c \"/host/$(basename "$ARCHIVE_PATH")\" | tar -xf - ;; \
    *.tar.gz|*.tgz) tar -xzf \"/host/$(basename "$ARCHIVE_PATH")\" ;; \
    *.tar) tar -xf \"/host/$(basename "$ARCHIVE_PATH")\" ;; \
    *) echo 'Unsupported archive format' && exit 3 ;; \
  esac; \
  chmod -R a+rwx /data/tiles /data/valhalla.json || true; \
  ls -lah /data | head"

echo "Starting valhalla..."
docker compose up -d valhalla

echo "Done. You can check:"
echo "  curl -fsS http://127.0.0.1:8002/isochrone (valhalla)"
echo "  curl -fsS http://127.0.0.1:8001/health (adapter)"
