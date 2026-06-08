package com.argusx.compliance.dto;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Inbound payload from the FastAPI compliance client. */
public class ThreatEventRequest {

    private String eventId;
    private String sessionId;
    private String riderId;
    private String threatLevel;
    private List<Map<String, Object>> hazards = new ArrayList<>();
    private CoordinatePayload coordinates;
    private Double speed;
    private String enrichedContext;
    private List<String> uiCommands = new ArrayList<>();
    private String timestamp;

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }
    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }
    public String getRiderId() { return riderId; }
    public void setRiderId(String riderId) { this.riderId = riderId; }
    public String getThreatLevel() { return threatLevel; }
    public void setThreatLevel(String threatLevel) { this.threatLevel = threatLevel; }
    public List<Map<String, Object>> getHazards() { return hazards; }
    public void setHazards(List<Map<String, Object>> hazards) { this.hazards = hazards; }
    public CoordinatePayload getCoordinates() { return coordinates; }
    public void setCoordinates(CoordinatePayload coordinates) { this.coordinates = coordinates; }
    public Double getSpeed() { return speed; }
    public void setSpeed(Double speed) { this.speed = speed; }
    public String getEnrichedContext() { return enrichedContext; }
    public void setEnrichedContext(String enrichedContext) { this.enrichedContext = enrichedContext; }
    public List<String> getUiCommands() { return uiCommands; }
    public void setUiCommands(List<String> uiCommands) { this.uiCommands = uiCommands; }
    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
}
