# Build Valhalla tiles on your PC (then upload to VPS)

This avoids VPS crashes (OOM/segfault) during `valhalla_build_tiles`.

## Requirements on your PC
- Docker (Desktop ok)
- Enough free disk space (Italy tiles can be **~10–20GB**)
- A stable internet connection
- (Optional) `zstd` installed locally (for faster compression). If you don't have it, use gzip.

## What you will produce
An archive containing:
- `tiles/` directory (Valhalla tiles)
- `valhalla.json` config used by Valhalla service

## 1) Clone the repo
```bash
git clone https://github.com/sight-agent/localrainbow.git
cd localrainbow
```

## 2) Build tiles locally (Italy)
Run:
```bash
./scripts/build_tiles_local.sh
```
This will:
- create a local folder `./artifacts/valhalla/`
- download `italy-latest.osm.pbf`
- build tiles into `./artifacts/valhalla/tiles/`
- write `./artifacts/valhalla/valhalla.json`
- create an archive `./artifacts/valhalla-italy.tar.zst` (or `.tar.gz`)

## 3) Upload the archive to the VPS
Option A (rsync, recommended):
```bash
rsync -avP ./artifacts/valhalla-italy.tar.zst root@46.225.97.145:/root/
```

Option B (scp):
```bash
scp ./artifacts/valhalla-italy.tar.zst root@46.225.97.145:/root/
```

If you use `.tar.gz`, upload that instead.

## 4) Install tiles into the Docker volume on the VPS
SSH into VPS:
```bash
ssh root@46.225.97.145
```
Then:
```bash
cd /root/.openclaw/workspace/localrainbow
./scripts/install_tiles_on_vps.sh /root/valhalla-italy.tar.zst
```

This will:
- stop valhalla
- extract into the docker volume `localrainbow_valhalla_tiles` at `/data/tiles` and `/data/valhalla.json`
- fix permissions
- start valhalla

## 5) Verify
On the VPS:
```bash
curl -fsS http://127.0.0.1:8001/health
curl -fsS https://mygptbots.xyz/adapter/health
```
And from your browser:
- https://mygptbots.xyz/ (click map and you should see colored isochrones)

## Notes / Windows
- On Windows, run these scripts inside WSL2 (Ubuntu) or Git Bash + Docker Desktop.
