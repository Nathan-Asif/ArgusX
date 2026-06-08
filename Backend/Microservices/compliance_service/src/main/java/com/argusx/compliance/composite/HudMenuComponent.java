package com.argusx.compliance.composite;

import java.util.List;
import java.util.Map;

/**
 * Lab 6 — Composite: uniform interface for HUD menu branches and leaves.
 */
public interface HudMenuComponent {
    String getName();
    String getType();
    Map<String, Object> toMap();
    List<HudMenuComponent> getChildren();
}
