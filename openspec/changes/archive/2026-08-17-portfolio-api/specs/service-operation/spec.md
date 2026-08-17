# Service Operation

## Purpose

Defines process health, dependency readiness, deterministic startup, and offline execution.

## ADDED Requirements

### Requirement: SYS-OPS-001 — Report process health

The service MUST expose `GET /health` independently of the `/api/v1` base path and MUST return `200` with `{ "status": "UP" }` when the process can serve HTTP.

#### Scenario: Process is operational while database is unavailable

- **Given** Fastify is serving requests
- **And** SQLite is unavailable
- **When** `/health` is requested
- **Then** the response remains `200` with status `UP`

### Requirement: SYS-OPS-002 — Report dependency readiness

The service MUST expose `GET /ready`. It MUST return `200` with `READY`, database `UP`, and schema version `1` only when SQLite is accessible and both schema-version markers are compatible; otherwise it MUST return `503` with `NOT_READY`.

#### Scenario: Database and schema are ready

- **Given** SQLite responds to a trivial statement
- **And** `PRAGMA user_version` and `schema_metadata` both report `1`
- **When** `/ready` is requested
- **Then** the API returns `200` with status `READY`

#### Scenario: Database is not ready

- **Given** SQLite is inaccessible or the schema version is incompatible
- **When** `/ready` is requested
- **Then** the API returns `503` with status `NOT_READY`

### Requirement: SYS-OPS-003 — Start without hidden data mutation

The runtime MUST require an existing database path and MUST NOT create, migrate, seed, repair, or select a fixture profile during API startup.

#### Scenario: Configured database file is absent

- **When** the service starts
- **Then** startup fails before listening
- **And** no empty database is created

### Requirement: SYS-OPS-004 — Run deterministically and offline

The service MUST run on Node.js 24 without outbound network access. It MUST accept an optional strict RFC 3339 fixed time and use the same normalized UTC instant for every clock read when configured.

#### Scenario: Fixed time is configured

- **Given** `MOCK_API_FIXED_TIME` contains a valid timestamp
- **When** multiple write operations request the current time
- **Then** each receives the same normalized UTC instant

#### Scenario: Runtime has no outbound network

- **Given** dependencies and assets were packaged during the build
- **When** the service starts and serves all accepted operations
- **Then** no external resource is required
