package com.argusx.compliance.composite;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class HudMenuBranch implements HudMenuComponent {

    private final String name;
    private final List<HudMenuComponent> children = new ArrayList<>();

    public HudMenuBranch(String name) {
        this.name = name;
    }

    public HudMenuBranch add(HudMenuComponent component) {
        children.add(component);
        return this;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public String getType() {
        return "branch";
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("name", name);
        map.put("type", "branch");
        map.put("children", children.stream().map(HudMenuComponent::toMap).toList());
        return map;
    }

    @Override
    public List<HudMenuComponent> getChildren() {
        return List.copyOf(children);
    }
}
