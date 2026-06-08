"""Runtime navigation arrow HUD overlay."""

from __future__ import annotations

from typing import Any

import pygame

ARROW_COLORS = {
    "LEFT": (255, 200, 80),
    "RIGHT": (255, 200, 80),
    "STRAIGHT": (80, 220, 160),
    "U_TURN": (255, 90, 90),
}


class ArgusXNavArrow:
    """Draws a direction arrow and instruction at the top-center of the HUD."""

    def __init__(self) -> None:
        self._title_font = pygame.font.SysFont("arial", 18, bold=True)
        self._sub_font = pygame.font.SysFont("arial", 14)

    def draw(self, surface: pygame.Surface, navigation: dict[str, Any] | None) -> None:
        if not navigation:
            return

        arrow = str(navigation.get("arrow", "STRAIGHT")).upper()
        instruction = str(navigation.get("instruction", ""))
        voice = str(navigation.get("voice_prompt", ""))
        distance_m = navigation.get("distance_m")
        if distance_m and "In " not in instruction:
            instruction = f"In {distance_m} m - {instruction}"
        color = ARROW_COLORS.get(arrow, (200, 200, 200))

        cx = surface.get_width() // 2
        top = 24
        box_w, box_h = 280, 110
        box = pygame.Rect(cx - box_w // 2, top, box_w, box_h)
        overlay = pygame.Surface((box_w, box_h), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 150))
        pygame.draw.rect(overlay, (*color, 120), overlay.get_rect(), 2, border_radius=10)

        self._draw_arrow_shape(overlay, arrow, color, box_w // 2, 42)
        title = self._title_font.render(arrow.replace("_", " "), True, color)
        overlay.blit(title, (box_w // 2 - title.get_width() // 2, 72))

        surface.blit(overlay, box.topleft)

        if instruction:
            inst = self._sub_font.render(instruction[:60], True, (230, 230, 240))
            surface.blit(inst, (cx - inst.get_width() // 2, top + box_h + 6))
        if voice:
            voice_surf = self._sub_font.render(f'"{voice[:50]}"', True, (160, 200, 255))
            surface.blit(voice_surf, (cx - voice_surf.get_width() // 2, top + box_h + 26))

    def _draw_arrow_shape(
        self, surface: pygame.Surface, direction: str, color: tuple[int, int, int], cx: int, cy: int
    ) -> None:
        size = 22
        if direction == "LEFT":
            points = [(cx - size, cy), (cx + size // 2, cy - size), (cx + size // 2, cy + size)]
        elif direction == "RIGHT":
            points = [(cx + size, cy), (cx - size // 2, cy - size), (cx - size // 2, cy + size)]
        elif direction == "U_TURN":
            pygame.draw.arc(surface, color, (cx - size, cy - size, size * 2, size * 2), 0.5, 2.8, 4)
            pygame.draw.polygon(
                surface,
                color,
                [(cx - size + 4, cy - 4), (cx - size - 8, cy - 8), (cx - size - 2, cy + 6)],
            )
            return
        else:  # STRAIGHT
            points = [(cx, cy - size), (cx - size // 2, cy + size // 3), (cx + size // 2, cy + size // 3)]
        pygame.draw.polygon(surface, color, points)
