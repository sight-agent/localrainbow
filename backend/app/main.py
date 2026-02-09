from __future__ import annotations

import os
from typing import Literal

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

VALHALLA_URL = os.environ.get("VALHALLA_URL", "http://valhalla:8002").rstrip("/")

app = FastAPI(title="localrainbow-adapter", version="0.1.0")


class IsochroneReq(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    mode: Literal["walk", "bike", "drive"] = "walk"
    minutes: list[int] = Field(default_factory=lambda: [10, 20, 30])


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/v1/isochrone")
async def isochrone(req: IsochroneReq):
    # Valhalla expects contours in minutes.
    contours = [{"time": int(m)} for m in req.minutes]

    # Map our modes to Valhalla costing.
    costing = {"walk": "pedestrian", "bike": "bicycle", "drive": "auto"}[req.mode]

    payload = {
        "locations": [{"lat": req.lat, "lon": req.lon}],
        "costing": costing,
        "contours": contours,
        "polygons": True,
        "generalize": 30,
    }

    url = f"{VALHALLA_URL}/isochrone"
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            r = await client.post(url, json=payload)
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"valhalla_unreachable: {e.__class__.__name__}")

    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"valhalla_error: {r.status_code}")

    return r.json()
