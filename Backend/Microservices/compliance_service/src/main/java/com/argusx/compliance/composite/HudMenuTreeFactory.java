package com.argusx.compliance.composite;

import org.springframework.stereotype.Component;

import java.util.Map;

/** Builds the default HUD simulation settings tree for a rider session. */
@Component
public class HudMenuTreeFactory {

    public HudMenuComponent buildDefaultTree(String riderId) {
        return new HudMenuBranch("simulation_settings")
                .add(new HudMenuBranch("display")
                        .add(new HudMenuLeaf("theme", "obsidian_void"))
                        .add(new HudMenuLeaf("glass_opacity", "0.30"))
                        .add(new HudMenuLeaf("argus_ring_profile", "quantum_violet")))
                .add(new HudMenuBranch("safety")
                        .add(new HudMenuLeaf("sentry_vision", "enabled"))
                        .add(new HudMenuLeaf("hud_sensitivity", "75"))
                        .add(new HudMenuLeaf("audio_alerts", "enabled")))
                .add(new HudMenuBranch("navigation")
                        .add(new HudMenuLeaf("voice_guidance", "enabled"))
                        .add(new HudMenuLeaf("arrow_overlay", "enabled"))
                        .add(new HudMenuLeaf("map_pin_density", "medium")))
                .add(new HudMenuLeaf("rider_id", riderId != null ? riderId : "anonymous"));
    }

    public Map<String, Object> buildDefaultTreeMap(String riderId) {
        return buildDefaultTree(riderId).toMap();
    }
}
