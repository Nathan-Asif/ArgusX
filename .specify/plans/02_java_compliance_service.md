# Plan 02 — Java Compliance Microservice

## Purpose

SDA design-pattern execution layer invoked asynchronously by FastAPI when `WARNING` or `CRITICAL` safety events occur.

## Integration contract

- **Ingress:** `POST /api/compliance/threat-event` (snake_case JSON from Python)
- **Settings:** `POST /api/compliance/menu-config` (Composite HUD menu tree)
- **Egress:** Observer audit log → fleet dashboard listeners

## Patterns

| Lab | Package | Implementation |
| --- | --- | --- |
| Singleton | `config` | `DatabaseConnectionPool` |
| Factory | `factory` | `ThreatIncidentFactory` |
| Builder | `builder` | `SafetyReportBuilder` |
| Composite | `composite` | `HudMenuBranch` / `HudMenuLeaf` |
| Null Object | `model` | `NullCoordinates` |
| Mediator + Observer | `mediator` | `ComplianceMediator` / `DashboardObserver` |

## Test

```bash
# Terminal 1
cd Backend/Microservices/compliance_service && mvn spring-boot:run

# Terminal 2
cd Backend && uv run python scripts/test_compliance_dispatch.py
```
