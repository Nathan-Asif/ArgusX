package com.argusx.compliance.factory;

import com.argusx.compliance.model.ThreatIncident;

import java.util.List;
import java.util.Map;

public class InfoThreatIncident implements ThreatIncident {

    @Override
    public String getLevel() {
        return "NORMAL";
    }

    @Override
    public String getSeverityLabel() {
        return "Corridor verified — no compliance escalation";
    }

    @Override
    public List<String> getRecommendedActions() {
        return List.of();
    }

    @Override
    public Map<String, Object> toMap() {
        return Map.of(
                "level", getLevel(),
                "severity", getSeverityLabel(),
                "actions", getRecommendedActions()
        );
    }
}
