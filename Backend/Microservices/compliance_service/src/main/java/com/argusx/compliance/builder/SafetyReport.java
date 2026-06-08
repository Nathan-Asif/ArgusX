package com.argusx.compliance.builder;

import java.util.List;
import java.util.Map;

/** Immutable safety report produced by the Builder pattern (Lab 4). */
public class SafetyReport {

    private final String eventId;
    private final String sessionId;
    private final String riderId;
    private final String threatLevel;
    private final String coordinatesSummary;
    private final double speed;
    private final String enrichedContext;
    private final List<String> uiCommands;
    private final List<Map<String, Object>> hazards;
    private final String timestamp;

    SafetyReport(
            String eventId,
            String sessionId,
            String riderId,
            String threatLevel,
            String coordinatesSummary,
            double speed,
            String enrichedContext,
            List<String> uiCommands,
            List<Map<String, Object>> hazards,
            String timestamp
    ) {
        this.eventId = eventId;
        this.sessionId = sessionId;
        this.riderId = riderId;
        this.threatLevel = threatLevel;
        this.coordinatesSummary = coordinatesSummary;
        this.speed = speed;
        this.enrichedContext = enrichedContext;
        this.uiCommands = uiCommands;
        this.hazards = hazards;
        this.timestamp = timestamp;
    }

    public String getEventId() { return eventId; }
    public String getSessionId() { return sessionId; }
    public String getRiderId() { return riderId; }
    public String getThreatLevel() { return threatLevel; }
    public String getCoordinatesSummary() { return coordinatesSummary; }
    public double getSpeed() { return speed; }
    public String getEnrichedContext() { return enrichedContext; }
    public List<String> getUiCommands() { return uiCommands; }
    public List<Map<String, Object>> getHazards() { return hazards; }
    public String getTimestamp() { return timestamp; }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new java.util.LinkedHashMap<>();
        map.put("event_id", eventId != null ? eventId : "");
        map.put("session_id", sessionId != null ? sessionId : "");
        map.put("rider_id", riderId != null ? riderId : "");
        map.put("threat_level", threatLevel != null ? threatLevel : "NORMAL");
        map.put("coordinates", coordinatesSummary != null ? coordinatesSummary : "");
        map.put("speed", speed);
        map.put("enriched_context", enrichedContext != null ? enrichedContext : "");
        map.put("ui_commands", uiCommands != null ? uiCommands : java.util.List.of());
        map.put("hazards", hazards != null ? hazards : java.util.List.of());
        map.put("timestamp", timestamp != null ? timestamp : "");
        return map;
    }
}
