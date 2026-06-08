package com.argusx.compliance.factory;

import com.argusx.compliance.model.ThreatIncident;
import org.springframework.stereotype.Component;

/**
 * Lab 3 — Factory: instantiates threat objects from runtime classifications
 * forwarded by the FastAPI agent routing layer.
 */
@Component
public class ThreatIncidentFactory {

    public ThreatIncident create(String threatLevel) {
        if (threatLevel == null) {
            return new InfoThreatIncident();
        }
        return switch (threatLevel.toUpperCase()) {
            case "CRITICAL" -> new CriticalThreatIncident();
            case "WARNING" -> new WarningThreatIncident();
            default -> new InfoThreatIncident();
        };
    }
}
