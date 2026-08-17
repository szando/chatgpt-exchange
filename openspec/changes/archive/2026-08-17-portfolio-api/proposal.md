# Change Proposal: Build Portfolio Demo API

Change ID: `CHG-BUILD-PORTFOLIO-API-001`  
Status: Completed and archived  
Archived: 2026-08-17

## Why

The PPM API Test Development Kit needs a deterministic, fully offline system under test that is realistic enough to exercise contract, filtering, lifecycle, data-quality, and error-handling tests. A fictional portfolio-management API avoids dependencies on production systems and confidential data while allowing test scenarios to be reproduced exactly.

## What changes

- Add direct GET retrieval for portfolios and allocation orders.
- Add POST query operations for positions, transactions, strategies, and performance.
- Add create, complete replacement, submit, and cancel operations for allocation orders.
- Validate request structure, business references, lifecycle, positive quantities, and each allocation percentage independently.
- Return RFC 9457 Problem Details with stable error codes.
- Store all business data in SQLite and seed it through deterministic fixture profiles.
- Preserve declared adverse data in business responses for external TDK validation.
- Add separate health and readiness endpoints.

## Capabilities

### New capabilities

- `portfolio-retrieval`
- `portfolio-queries`
- `allocation-orders`
- `error-handling`
- `service-operation`

### Modified capabilities

None. This change establishes the initial system.

## Public API surface

| Trace ID | Operation |
|---|---|
| `OP-PORT-GET-001` | `GET /api/v1/portfolios/{portfolioId}` |
| `OP-POS-QUERY-001` | `POST /api/v1/positions/query` |
| `OP-TXN-QUERY-001` | `POST /api/v1/transactions/query` |
| `OP-STRAT-QUERY-001` | `POST /api/v1/strategies/query` |
| `OP-PERF-QUERY-001` | `POST /api/v1/performance/query` |
| `OP-ALLOC-CREATE-001` | `POST /api/v1/allocation-orders` |
| `OP-ALLOC-GET-001` | `GET /api/v1/allocation-orders/{allocationOrderId}` |
| `OP-ALLOC-UPDATE-001` | `PUT /api/v1/allocation-orders/{allocationOrderId}` |
| `OP-ALLOC-SUBMIT-001` | `POST /api/v1/allocation-orders/{allocationOrderId}/submit` |
| `OP-ALLOC-CANCEL-001` | `POST /api/v1/allocation-orders/{allocationOrderId}/cancel` |
| — | `GET /health` and `GET /ready` |

## Impact

- Adds two OpenAPI 3.0.3 contracts.
- Adds a Node.js 24/TypeScript/Fastify application boundary.
- Adds a permissive SQLite schema, fixture format, seeder, and fixture validator.
- Adds no authentication, pagination, external network dependency, or consumer-specific logic.

## Outcome

The change was completed as the accepted baseline design. Its applied requirements now live under `openspec/specs/`; this archived directory preserves the proposal, design, tasks, and original capability deltas.

