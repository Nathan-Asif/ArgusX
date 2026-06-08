package com.argusx.compliance.factory;

import com.argusx.compliance.model.ThreatIncident;

import java.util.List;
import java.util.Map;

public class CriticalThreatIncident implements ThreatIncident {

    @Override
    public String getLevel() {
        return "CRITICAL";
    }

    @Override
    public String getSeverityLabel() {
        return "Immediate intervention required";
    }

    @Override
    public List<String> getRecommendedActions() {
        return List.of("TRIGGER_HUD_ALERTS", "PRUNE_NON_ESSENTIAL_WIDGETS", "LOG_COMPLIANCE_RECORD");
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
