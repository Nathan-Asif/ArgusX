"""HUD minimap — Google Static Maps tiles + route overlay fallback."""

from __future__ import annotations

from typing import Any

import pygame

from simulator.argusx_polyline import decode_polyline

MAP_BOUNDS = {
    "lat_min": 37.755,
    "lat_max": 37.790,
    "lng_min": -122.445,
    "lng_max": -122.410,
}

RISK_COLORS = {
    "low": (80, 200, 120),
    "moderate": (200, 180, 60),
    "elevated": (255, 140, 50),
    "high": (255, 70, 70),
}
DESTINATION_COLOR = (255, 80, 120)
ROUTE_COLOR = (66, 133, 244)


class ArgusXMapPanel:
    """Renders a bottom-right minimap with optional Google road-map background."""

    def __init__(self, width: int = 340, height: int = 220) -> None:
        self.width = width
        self.height = height
        self._font = None
        self._static_map: pygame.Surface | None = None
        self._static_map_key: str = ""

    def set_static_map(self, surface: pygame.Surface | None, cache_key: str = "") -> None:
        self._static_map = surface
        self._static_map_key = cache_key

    def _ensure_font(self) -> pygame.font.Font:
        if self._font is None:
            self._font = pygame.font.SysFont("consolas", 11)
        return self._font

    def _resolve_bounds(
        self,
        rider_lat: float,
        rider_lng: float,
        pinned_pois: list[dict[str, Any]],
        route_visualization: dict[str, Any] | None,
    ) -> dict[str, float]:
        lats = [rider_lat]
        lngs = [rider_lng]
        if route_visualization:
            for key in ("origin", "destination"):
                point = route_visualization.get(key) or {}
                if point.get("lat") is not None and point.get("lng") is not None:
                    lats.append(float(point["lat"]))
                    lngs.append(float(point["lng"]))
        for poi in pinned_pois:
            if poi.get("lat") is not None and poi.get("lng") is not None:
                lats.append(float(poi["lat"]))
                lngs.append(float(poi["lng"]))
        if route_visualization and route_visualization.get("polyline"):
            for plat, plng in decode_polyline(str(route_visualization["polyline"])):
                lats.append(plat)
                lngs.append(plng)

        if len(lats) <= 2 and all(37.7 < lat < 37.8 for lat in lats):
            return MAP_BOUNDS

        lat_min, lat_max = min(lats), max(lats)
        lng_min, lng_max = min(lngs), max(lngs)
        lat_pad = max(0.002, (lat_max - lat_min) * 0.12)
        lng_pad = max(0.002, (lng_max - lng_min) * 0.12)
        return {
            "lat_min": lat_min - lat_pad,
            "lat_max": lat_max + lat_pad,
            "lng_min": lng_min - lng_pad,
            "lng_max": lng_max + lng_pad,
        }

    def _to_pixel(self, lat: float, lng: float, bounds: dict[str, float]) -> tuple[int, int]:
        lat_span = bounds["lat_max"] - bounds["lat_min"]
        lng_span = bounds["lng_max"] - bounds["lng_min"]
        x = int((lng - bounds["lng_min"]) / lng_span * (self.width - 24)) + 12
        y = int((bounds["lat_max"] - lat) / lat_span * (self.height - 36)) + 12
        return x, y

    def draw(
        self,
        surface: pygame.Surface,
        pos: tuple[int, int],
        rider_lat: float,
        rider_lng: float,
        pinned_pois: list[dict[str, Any]],
        spatial_zones: list[dict[str, Any]] | None = None,
        route_visualization: dict[str, Any] | None = None,
    ) -> None:
        panel = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
        font = self._ensure_font()

        route_source = str((route_visualization or {}).get("source", ""))
        has_google_route = route_visualization and route_source == "google_directions"

        if self._static_map is not None and has_google_route:
            panel.blit(self._static_map, (0, 0))
            overlay = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 60))
            panel.blit(overlay, (0, 0))
        else:
            panel.fill((0, 0, 0, 140))
            for i in range(1, 4):
                gx = int(self.width * i / 4)
                gy = int((self.height - 20) * i / 4) + 20
                pygame.draw.line(panel, (60, 60, 80, 80), (8, gy), (self.width - 8, gy), 1)
                pygame.draw.line(panel, (60, 60, 80, 80), (gx, 24), (gx, self.height - 8), 1)

        pygame.draw.rect(panel, (139, 92, 246, 120), panel.get_rect(), 1, border_radius=8)

        if has_google_route:
            title_text = "GOOGLE MAP + ROUTE"
        elif route_visualization:
            title_text = "ROUTE MAP"
        else:
            title_text = "SPATIAL MAP (local zones)"
        title_bg = pygame.Surface((self.width - 8, 18), pygame.SRCALPHA)
        title_bg.fill((0, 0, 0, 160))
        panel.blit(title_bg, (4, 4))
        panel.blit(font.render(title_text, True, (230, 230, 240)), (10, 6))

        bounds = self._resolve_bounds(rider_lat, rider_lng, pinned_pois, route_visualization)
        rx, ry = self._to_pixel(rider_lat, rider_lng, bounds)

        if route_visualization and not self._static_map:
            polyline = str(route_visualization.get("polyline", ""))
            path_points = decode_polyline(polyline)
            if len(path_points) >= 2:
                pixel_path = [self._to_pixel(plat, plng, bounds) for plat, plng in path_points]
                pygame.draw.lines(panel, ROUTE_COLOR, False, pixel_path, 4)

        if spatial_zones and not has_google_route:
            for zone in spatial_zones:
                zlat = zone.get("lat")
                zlng = zone.get("lng")
                if zlat is None or zlng is None:
                    continue
                zx, zy = self._to_pixel(float(zlat), float(zlng), bounds)
                color = RISK_COLORS.get(str(zone.get("risk_profile", "low")), (120, 120, 140))
                pygame.draw.circle(panel, color, (zx, zy), 14, 1)

        if route_visualization and route_visualization.get("destination"):
            dest = route_visualization["destination"]
            if dest.get("lat") is not None and dest.get("lng") is not None and not self._static_map:
                dx, dy = self._to_pixel(float(dest["lat"]), float(dest["lng"]), bounds)
                pygame.draw.circle(panel, DESTINATION_COLOR, (dx, dy), 8)
                pygame.draw.circle(panel, (255, 255, 255), (dx, dy), 8, 2)

        for poi in pinned_pois:
            if poi.get("pin_type") == "destination" or self._static_map:
                continue
            lat = poi.get("lat")
            lng = poi.get("lng")
            if lat is not None and lng is not None:
                px, py = self._to_pixel(float(lat), float(lng), bounds)
                pygame.draw.circle(panel, (160, 160, 200), (px, py), 5)

        # Rider dot always visible on top
        pygame.draw.circle(panel, (6, 182, 212), (rx, ry), 8)
        pygame.draw.circle(panel, (255, 255, 255), (rx, ry), 8, 2)
        panel.blit(font.render("YOU", True, (6, 222, 255)), (rx + 10, ry - 6))

        remaining = (route_visualization or {}).get("distance_remaining_m")
        if remaining:
            panel.blit(
                font.render(f"{int(remaining) / 1000:.1f} km left", True, (200, 230, 255)),
                (10, self.height - 34),
            )

        coords = font.render(f"{rider_lat:.5f}, {rider_lng:.5f}", True, (210, 210, 220))
        panel.blit(coords, (10, self.height - 18))

        surface.blit(panel, pos)
