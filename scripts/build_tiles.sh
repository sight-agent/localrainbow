#!/usr/bin/env bash
set -euo pipefail

# Builds Valhalla tiles for Italy into the `valhalla_tiles` docker volume.
# This can take a while and requires some disk.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/3] Starting valhalla container (for volume)..."
docker compose up -d valhalla

VOL_NAME="localrainbow_valhalla_tiles"

echo "[2/3] Downloading Italy PBF into volume ($VOL_NAME)..."
# Put the PBF into the volume at /data/italy-latest.osm.pbf
TMP_C="$(docker create -v ${VOL_NAME}:/data alpine:3.19)"
docker start -a "$TMP_C" >/dev/null 2>&1 || true
# Use a second container with curl to download into the volume

docker run --rm -v ${VOL_NAME}:/data curlimages/curl:8.6.0 \
  -L -o /data/italy-latest.osm.pbf \
  https://download.geofabrik.de/europe/italy-latest.osm.pbf

# Cleanup temp container
 docker rm -f "$TMP_C" >/dev/null 2>&1 || true

echo "[3/3] Building tiles (this can take many minutes)..."
docker run --rm -v ${VOL_NAME}:/data ghcr.io/valhalla/valhalla:latest \
  bash -lc "valhalla_build_config --mjolnir-tile-dir /data/tiles --mjolnir-tile-extract /data/italy-latest.osm.pbf --mjolnir-timezone /data/timezones.sqlite && valhalla_build_tiles -c /data/valhalla.json /data/italy-latest.osm.pbf && valhalla_build_admins -c /data/valhalla.json /data/italy-latest.osm.pbf"

echo "Tiles built. Restarting stack..."
docker compose restart valhalla
