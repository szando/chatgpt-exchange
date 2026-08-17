# Design: Portfolio Demo API Baseline

## Context

The service is a real mock API and a deterministic TDK system under test. It runs mainly in Linux containers but must also run on Windows. It uses no production data, credentials, identity provider, or online service. The complete design is elaborated in `docs/system-architecture-and-implementation-design.md`.

## Decisions

### Contract and transport

OpenAPI 3.0.3 is the public contract. Fastify validates request bodies and parameters using generated trusted schemas. Business routes do not attach response schemas or schema-driven serializers because adverse fixture values must survive the HTTP boundary unchanged.

### Data source

Node.js 24's built-in `node:sqlite` module supplies the runtime database. The API opens an existing seeded database and never seeds or migrates it implicitly. Business tables deliberately omit foreign keys, uniqueness constraints, and business `CHECK` constraints; application services validate writes, while fixture validation detects and declares stored defects.

### Application boundary

Thin route handlers call application services. Services coordinate business validation and repositories. Multi-statement writes use `BEGIN IMMEDIATE`, with rollback on every failure. Repositories use prepared statements, explicit sorting, and cardinality checks rather than assuming public identifiers are unique.

### Determinism

A fixed clock can be injected through `MOCK_API_FIXED_TIME`. The baseline sequence produces `AORD-5004` for the first created order. Fixture profiles create fresh databases from reviewable JSON and controlled SQL mutations.

### Decimal representation

Quantities and percentages are API strings. Valid writes canonicalize quantities to four decimal places and allocation percentages to two. Percentage validation operates on exact decimal representations rather than binary floating-point comparisons.

### Allocation lifecycle

New orders are `DRAFT`. Only drafts can be replaced or submitted. Drafts and submitted orders can be cancelled. Submission revalidates the currently stored content. Cancellation deliberately does not revalidate content.

## Validation order

Allocation-order commands process validation in this order:

1. HTTP parsing and request schema.
2. Path identifier format and target-order cardinality where applicable.
3. Lifecycle eligibility.
4. Portfolio, instrument, strategy, status, and availability references.
5. Duplicate strategies.
6. Quantity and each allocation percentage independently.
7. Client-order-reference conflict.
8. Transactional write.

Safe, independent semantic violations may be accumulated. Later checks that depend on invalid earlier values are skipped.

## Adverse-data behavior

Base rows are loaded before related master summaries. A missing master leaves its reference identifier intact and causes the nested summary to be omitted. A duplicate public identifier is ambiguous and produces generic `500`, never an arbitrary selection. Required stored nulls and incorrect stored scalar types remain observable.

## Traceability summary

| Capability | Requirements | Operations |
|---|---|---|
| Portfolio retrieval | `REQ-PORT-001` | `OP-PORT-GET-001` |
| Shared query behavior | `REQ-QUERY-001`–`004` | Four POST queries |
| Positions | `REQ-POS-001` | `OP-POS-QUERY-001` |
| Transactions | `REQ-TXN-001` | `OP-TXN-QUERY-001` |
| Strategies | `REQ-STRAT-001` | `OP-STRAT-QUERY-001` |
| Performance | `REQ-PERF-001` | `OP-PERF-QUERY-001` |
| Allocation orders | `REQ-ALLOC-001`–`008` | Five allocation-order operations |
| Common failures/data | `SYS-ERR-001`–`003`, `SYS-DATA-001`–`002` | All business operations |
| Runtime operation | `SYS-OPS-001`–`004` | `/health`, `/ready`, startup |

## Risks and controls

| Risk | Control |
|---|---|
| Response serialization hides defects | No business response schema; validate serialized HTTP payloads in tests. |
| Permissive SQLite creates undefined reads | Explicit cardinality rules and deterministic row tie-breakers. |
| Tests contaminate one another | Fresh temporary database for each isolated test scope. |
| Time and IDs drift | Injected clock and transactional database sequence. |
| Container requires online resources | Lockfile build and locally packaged runtime assets. |

