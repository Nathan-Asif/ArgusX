# ArgusX Java Compliance Service

SDA design-pattern microservice invoked asynchronously by the Python FastAPI orchestrator.

## Patterns implemented

| Lab | Package | Class |
| --- | --- | --- |
| Singleton (Lab 2) | `com.argusx.compliance.config` | `DatabaseConnectionPool` |
| Factory (Lab 3) | `com.argusx.compliance.factory` | `ThreatIncidentFactory` |
| Builder (Lab 4) | `com.argusx.compliance.builder` | `SafetyReportBuilder` |
| Composite (Lab 6) | `com.argusx.compliance.composite` | `HudMenuBranch` / `HudMenuLeaf` |
| Null Object (Lab 8) | `com.argusx.compliance.model` | `NullCoordinates` |
| Mediator + Observer (Lab 9) | `com.argusx.compliance.mediator` | `ComplianceMediator` / `DashboardObserver` |

## Run

```bash
cd Backend/Microservices/compliance_service
mvn spring-boot:run
```

Service starts on `http://127.0.0.1:8081`.

## API

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/api/compliance/health` | Service health |
| `POST` | `/api/compliance/threat-event` | Process threat incident from FastAPI |
| `POST` | `/api/compliance/menu-config` | Return HUD settings Composite tree |
| `GET` | `/api/compliance/audit-log` | Recent in-memory audit records |

## Test with Python

```bash
# Terminal 1 — Java service
mvn spring-boot:run

# Terminal 2 — Python test script
cd Backend
uv run python scripts/test_compliance_dispatch.py
```
