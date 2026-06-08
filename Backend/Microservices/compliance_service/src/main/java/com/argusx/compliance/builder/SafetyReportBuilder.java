package com.argusx.compliance.builder;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Lab 4 — Builder: assembles complex safety reports step-by-step before
 * database ingestion.
 */
public class SafetyReportBuilder {

    private String eventId = UUID.randomUUID().toString();
    private String sessionId = "unknown-session";
    private String riderId = "anonymous";
    private String threatLevel = "NORMAL";
    private String coordinatesSummary = "NULL_COORDINATES";
    private double speed = 0.0;
    private String enrichedContext = "";
    private List<String> uiCommands = new ArrayList<>();
    private List<Map<String, Object>> hazards = new ArrayList<>();
    private String timestamp = java.time.Instant.now().toString();

    public SafetyReportBuilder eventId(String eventId) {
        this.eventId = eventId;
        return this;
    }

    public SafetyReportBuilder sessionId(String sessionId) {
        this.sessionId = sessionId;
        return this;
    }

    public SafetyReportBuilder riderId(String riderId) {
        this.riderId = riderId;
        return this;
    }

    public SafetyReportBuilder threatLevel(String threatLevel) {
        this.threatLevel = threatLevel;
        return this;
    }

    public SafetyReportBuilder coordinatesSummary(String coordinatesSummary) {
        this.coordinatesSummary = coordinatesSummary;
        return this;
    }

    public SafetyReportBuilder speed(double speed) {
        this.speed = speed;
        return this;
    }

    public SafetyReportBuilder enrichedContext(String enrichedContext) {
        this.enrichedContext = enrichedContext;
        return this;
    }

    public SafetyReportBuilder uiCommands(List<String> uiCommands) {
        this.uiCommands = uiCommands != null ? uiCommands : new ArrayList<>();
        return this;
    }

    public SafetyReportBuilder hazards(List<Map<String, Object>> hazards) {
        this.hazards = hazards != null ? hazards : new ArrayList<>();
        return this;
    }

    public SafetyReportBuilder timestamp(String timestamp) {
        this.timestamp = timestamp;
        return this;
    }

    public SafetyReport build() {
        return new SafetyReport(
                eventId,
                sessionId,
                riderId,
                threatLevel,
                coordinatesSummary,
                speed,
                enrichedContext,
                uiCommands,
                hazards,
                timestamp
        );
    }
}
