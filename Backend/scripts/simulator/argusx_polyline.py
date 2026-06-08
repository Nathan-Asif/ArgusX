"""Decode Google Maps encoded polylines for the HUD minimap."""

from __future__ import annotations


def decode_polyline(encoded: str) -> list[tuple[float, float]]:
    """Return (lat, lng) pairs from a Google encoded polyline string."""
    if not encoded or encoded.startswith("mock_"):
        return []

    coords: list[tuple[float, float]] = []
    index = 0
    lat = 0
    lng = 0
    length = len(encoded)

    while index < length:
        shift = 0
        result = 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        delta_lat = ~(result >> 1) if (result & 1) else (result >> 1)
        lat += delta_lat

        shift = 0
        result = 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        delta_lng = ~(result >> 1) if (result & 1) else (result >> 1)
        lng += delta_lng

        coords.append((lat / 1e5, lng / 1e5))

    return coords
