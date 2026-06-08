package com.argusx.compliance.composite;

import java.util.Collections;
import java.util.List;
import java.util.Map;

public class HudMenuLeaf implements HudMenuComponent {

    private final String name;
    private final String value;

    public HudMenuLeaf(String name, String value) {
        this.name = name;
        this.value = value;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public String getType() {
        return "leaf";
    }

    @Override
    public Map<String, Object> toMap() {
        return Map.of("name", name, "type", "leaf", "value", value);
    }

    @Override
    public List<HudMenuComponent> getChildren() {
        return Collections.emptyList();
    }
}
