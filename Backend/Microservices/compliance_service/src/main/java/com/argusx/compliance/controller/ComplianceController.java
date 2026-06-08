package com.argusx.compliance.controller;

import com.argusx.compliance.composite.HudMenuTreeFactory;
import com.argusx.compliance.config.DatabaseConnectionPool;
import com.argusx.compliance.dto.MenuConfigRequest;
import com.argusx.compliance.dto.ThreatEventRequest;
import com.argusx.compliance.mediator.ComplianceMediator;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/compliance")
public class ComplianceController {

    private final ComplianceMediator mediator;
    private final HudMenuTreeFactory menuTreeFactory;
    private final DatabaseConnectionPool connectionPool;

    public ComplianceController(
            ComplianceMediator mediator,
            HudMenuTreeFactory menuTreeFactory,
            DatabaseConnectionPool connectionPool
    ) {
        this.mediator = mediator;
        this.menuTreeFactory = menuTreeFactory;
        this.connectionPool = connectionPool;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "service", "argusx-compliance-service",
                "database_configured", connectionPool.isConfigured(),
                "database_connected", connectionPool.isConnected()
        ));
    }

    @PostMapping("/threat-event")
    public ResponseEntity<Map<String, Object>> threatEvent(@RequestBody ThreatEventRequest request) {
        return ResponseEntity.ok(mediator.processThreatEvent(request));
    }

    @PostMapping("/menu-config")
    public ResponseEntity<Map<String, Object>> menuConfig(@RequestBody MenuConfigRequest request) {
        String riderId = request.getRiderId() != null ? request.getRiderId() : "anonymous";
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "request_type", request.getRequestType(),
                "rider_id", riderId,
                "menu_tree", menuTreeFactory.buildDefaultTreeMap(riderId)
        ));
    }

    @GetMapping("/audit-log")
    public ResponseEntity<Map<String, Object>> auditLog() {
        return ResponseEntity.ok(Map.of(
                "status", "ok",
                "records", mediator.getAuditLog()
        ));
    }
}
