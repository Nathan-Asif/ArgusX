package com.argusx.compliance.model;

import java.util.List;
import java.util.Map;

/** Structural threat event contract produced by the Factory pattern (Lab 3). */
public interface ThreatIncident {
    String getLevel();
    String getSeverityLabel();
    List<String> getRecommendedActions();
    Map<String, Object> toMap();
}
