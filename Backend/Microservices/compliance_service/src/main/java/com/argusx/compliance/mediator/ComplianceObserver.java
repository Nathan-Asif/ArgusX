package com.argusx.compliance.mediator;

import com.argusx.compliance.builder.SafetyReport;

/** Lab 9 — Observer: receives compliance events for dashboard notification. */
public interface ComplianceObserver {
    void onSafetyReportPersisted(SafetyReport report);
}
