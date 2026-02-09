#!/usr/bin/env bash
set -euo pipefail

# Build Valhalla tiles locally (Italy) into ./artifacts/valhalla
# Produces ./artifacts/valhalla-italy.tar.zst (or .tar.gz)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p artifacts/valhalla

PBF_URL="https://download.geofabrik.de/europe/italy-latest.osm.pbf"
PBF_PATH="artifacts/valhalla/italy-latest.osm.pbf"
OUT_DIR="artifacts/valhalla"

if [ ! -f "$PBF_PATH" ]; then
  echo "Downloading PBF..."
  curl -L -o "$PBF_PATH" "$PBF_URL"
else
  echo "PBF already present: $PBF_PATH"
fi

echo "Building tiles (this can take a while)..."
rm -rf "$OUT_DIR/tiles"
mkdir -p "$OUT_DIR/tiles"

# Generate config to stdout and redirect to file.
docker run --rm \
  -v "$ROOT_DIR/$OUT_DIR":/data \
  ghcr.io/valhalla/valhalla:latest \
  bash -lc "valhalla_build_config --mjolnir-tile-dir /data/tiles > /data/valhalla.json"

# Build tiles (use all local cores by default; reduce with -j if you hit RAM issues)
docker run --rm \
  -v "$ROOT_DIR/$OUT_DIR":/data \
  ghcr.io/valhalla/valhalla:latest \
  bash -lc "valhalla_build_tiles -c /data/valhalla.json /data/italy-latest.osm.pbf && valhalla_build_admins -c /data/valhalla.json /data/italy-latest.osm.pbf"

echo "Creating archive..."
ARCH_ZST="artifacts/valhalla-italy.tar.zst"
ARCH_GZ="artifacts/valhalla-italy.tar.gz"

if command -v zstd >/dev/null 2>&1; then
  tar -C "$OUT_DIR" -cf - tiles valhalla.json | zstd -19 -T0 -o "$ARCH_ZST"
  echo "Created: $ARCH_ZST"
else
  tar -C "$OUT_DIR" -czf "$ARCH_GZ" tiles valhalla.json
  echo "Created: $ARCH_GZ (install zstd for faster compression)"
fi

echo "Done. Upload the archive to the VPS and run install_tiles_on_vps.sh there."
