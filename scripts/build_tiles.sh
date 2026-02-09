#!/usr/bin/env bash
set -euo pipefail

# Builds Valhalla tiles for Italy into the `valhalla_tiles` docker volume.
# This can take a while and requires some disk.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/4] Stopping valhalla service (avoid restart storms during build)..."
docker compose stop valhalla || true

echo "[2/4] Starting valhalla container (for volume)..."
# We just need the volume; valhalla will be started again after the build.

VOL_NAME="localrainbow_valhalla_tiles"

echo "[3/4] Downloading Italy PBF into volume ($VOL_NAME)..."
# Ensure permissions inside the volume allow writes from helper containers.
docker run --rm -v ${VOL_NAME}:/data alpine:3.19 sh -lc "chmod -R a+rwx /data || true"

if docker run --rm -v ${VOL_NAME}:/data alpine:3.19 sh -lc "test -f /data/italy-latest.osm.pbf"; then
  echo "PBF already present, skipping download."
else
  docker run --rm -u 0:0 -v ${VOL_NAME}:/data curlimages/curl:8.6.0 \
    -L -o /data/italy-latest.osm.pbf \
    https://download.geofabrik.de/europe/italy-latest.osm.pbf
fi

echo "[4/4] Building tiles (this can take many minutes)..."
docker run --rm -v ${VOL_NAME}:/data ghcr.io/valhalla/valhalla:latest \
  bash -lc "mkdir -p /data/tiles \
    && valhalla_build_config --mjolnir-tile-dir /data/tiles > /data/valhalla.json \
    && valhalla_build_tiles -c /data/valhalla.json -j 1 /data/italy-latest.osm.pbf \
    && valhalla_build_admins -c /data/valhalla.json /data/italy-latest.osm.pbf"

echo "Tiles built. Starting valhalla service..."
docker compose up -d valhalla
