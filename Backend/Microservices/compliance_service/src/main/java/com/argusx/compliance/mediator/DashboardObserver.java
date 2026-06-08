package com.argusx.compliance.mediator;

import com.argusx.compliance.builder.SafetyReport;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Lab 9 — Observer: captures persisted safety reports for fleet dashboard
 * listeners. In-memory store until Supabase realtime wiring is added.
 */
@Component
public class DashboardObserver implements ComplianceObserver {

    private static final Logger log = LoggerFactory.getLogger(DashboardObserver.class);
    private final List<Map<String, Object>> auditLog = new ArrayList<>();

    @Override
    public synchronized void onSafetyReportPersisted(SafetyReport report) {
        auditLog.add(0, report.toMap());
        if (auditLog.size() > 100) {
            auditLog.remove(auditLog.size() - 1);
        }
        log.info("DashboardObserver notified: event_id={} threat={}", report.getEventId(), report.getThreatLevel());
    }

    public synchronized List<Map<String, Object>> getRecentAuditLog() {
        return List.copyOf(auditLog);
    }
}
