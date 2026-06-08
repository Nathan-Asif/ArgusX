package com.argusx.compliance.factory;

import com.argusx.compliance.model.ThreatIncident;

import java.util.List;
import java.util.Map;

public class WarningThreatIncident implements ThreatIncident {

    @Override
    public String getLevel() {
        return "WARNING";
    }

    @Override
    public String getSeverityLabel() {
        return "Elevated situational risk detected";
    }

    @Override
    public List<String> getRecommendedActions() {
        return List.of("TRIGGER_HUD_ALERTS", "LOG_COMPLIANCE_RECORD");
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
