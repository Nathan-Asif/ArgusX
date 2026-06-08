package com.argusx.compliance.mediator;

import com.argusx.compliance.builder.SafetyReport;
import com.argusx.compliance.builder.SafetyReportBuilder;
import com.argusx.compliance.config.DatabaseConnectionPool;
import com.argusx.compliance.dto.ThreatEventRequest;
import com.argusx.compliance.factory.ThreatIncidentFactory;
import com.argusx.compliance.model.Coordinates;
import com.argusx.compliance.model.CoordinatesResolver;
import com.argusx.compliance.model.ThreatIncident;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Lab 9 — Mediator: coordinates Factory, Builder, Singleton pool, and
 * Observer notifications without tight coupling between subsystems.
 */
@Service
public class ComplianceMediator {

    private final ThreatIncidentFactory threatFactory;
    private final DatabaseConnectionPool connectionPool;
    private final List<ComplianceObserver> observers;

    public ComplianceMediator(
            ThreatIncidentFactory threatFactory,
            DatabaseConnectionPool connectionPool,
            DashboardObserver dashboardObserver
    ) {
        this.threatFactory = threatFactory;
        this.connectionPool = connectionPool;
        this.observers = List.of(dashboardObserver);
    }

    public Map<String, Object> processThreatEvent(ThreatEventRequest request) {
        connectionPool.connect();

        Coordinates coordinates = CoordinatesResolver.resolve(request.getCoordinates());
        ThreatIncident incident = threatFactory.create(request.getThreatLevel());

        SafetyReport report = new SafetyReportBuilder()
                .eventId(request.getEventId() != null ? request.getEventId() : java.util.UUID.randomUUID().toString())
                .sessionId(request.getSessionId() != null ? request.getSessionId() : "unknown-session")
                .riderId(request.getRiderId() != null ? request.getRiderId() : "anonymous")
                .threatLevel(incident.getLevel())
                .coordinatesSummary(coordinates.describe())
                .speed(request.getSpeed() != null ? request.getSpeed() : 0.0)
                .enrichedContext(request.getEnrichedContext() != null ? request.getEnrichedContext() : "")
                .uiCommands(request.getUiCommands())
                .hazards(request.getHazards())
                .timestamp(request.getTimestamp() != null ? request.getTimestamp() : java.time.Instant.now().toString())
                .build();

        persistReport(report);

        return Map.of(
                "status", "accepted",
                "event_id", report.getEventId(),
                "threat_incident", incident.toMap(),
                "safety_report", report.toMap(),
                "database_connected", connectionPool.isConnected()
        );
    }

    private void persistReport(SafetyReport report) {
        // In-memory + observer broadcast; JDBC insert when pool is configured.
        for (ComplianceObserver observer : observers) {
            observer.onSafetyReportPersisted(report);
        }
    }

    public List<Map<String, Object>> getAuditLog() {
        for (ComplianceObserver observer : observers) {
            if (observer instanceof DashboardObserver dashboardObserver) {
                return dashboardObserver.getRecentAuditLog();
            }
        }
        return new ArrayList<>();
    }
}
