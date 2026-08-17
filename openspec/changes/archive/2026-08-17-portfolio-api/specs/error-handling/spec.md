# Error Handling and Adverse Data

## Purpose

Defines common HTTP failures and the preservation of deliberately adverse stored responses.

## ADDED Requirements

### Requirement: SYS-ERR-001 — Return RFC 9457 Problem Details

Every documented business error MUST use `application/problem+json` and contain `type`, `title`, `status`, `detail`, `instance`, stable `code`, and `violations` fields.

#### Scenario: Expected client or domain failure occurs

- **When** an expected error is mapped to HTTP
- **Then** the status and stable code match the OpenAPI operation
- **And** the response contains no stack trace, SQL, or filesystem path

### Requirement: SYS-ERR-002 — Distinguish transport and request failures

Malformed JSON and schema-invalid requests MUST return `400`; unsupported request media types MUST return `415`.

#### Scenario: Malformed JSON is received

- **When** a business route receives malformed JSON
- **Then** the API returns `400 Bad Request`
- **And** the code is `MALFORMED_JSON`

#### Scenario: Unsupported content type is received

- **When** a JSON business operation receives an unsupported media type
- **Then** the API returns `415 Unsupported Media Type`
- **And** the code is `UNSUPPORTED_MEDIA_TYPE`

### Requirement: SYS-ERR-003 — Distinguish unavailable and inconsistent data sources

An unavailable database MUST produce `503 DATA_SOURCE_UNAVAILABLE`. An unexpected repository or consistency failure MUST produce generic `500 INTERNAL_SERVER_ERROR` while retaining its cause only in logs.

#### Scenario: Database cannot serve a business request

- **When** SQLite is unavailable beyond the configured boundary
- **Then** the API returns `503 Service Unavailable`
- **And** the code is `DATA_SOURCE_UNAVAILABLE`

#### Scenario: Unexpected internal failure occurs

- **When** an error is not a documented client or domain condition
- **Then** the API returns `500 Internal Server Error`
- **And** the code is `INTERNAL_SERVER_ERROR`

### Requirement: SYS-DATA-001 — Preserve contract-visible adverse data

Business responses MUST use ordinary JSON serialization and MUST NOT be validated, stripped, coerced, or repaired against response schemas at runtime.

#### Scenario: Required stored value is null

- **Given** an adverse fixture stores `NULL` for a required scalar
- **When** the record is returned
- **Then** the field is emitted as JSON `null`

#### Scenario: Related master is missing

- **Given** a base record retains a reference identifier whose master record is absent
- **When** the base record is returned
- **Then** the top-level reference identifier remains
- **And** the unavailable nested summary is omitted

#### Scenario: Stored scalar has the wrong type

- **Given** an adverse fixture stores a contract-visible scalar using the wrong SQLite storage class
- **When** the record is returned
- **Then** the wrong JSON scalar type remains observable

### Requirement: SYS-DATA-002 — Reject ambiguous public identifiers

The API MUST NOT arbitrarily select among duplicate stored rows sharing a public identifier.

#### Scenario: Requested resource identifier is duplicated

- **Given** more than one stored resource has the requested public identifier
- **When** a resource operation loads it
- **Then** the API returns generic `500 INTERNAL_SERVER_ERROR`
- **And** the ambiguity is recorded in internal diagnostics

#### Scenario: Related master identifier is duplicated

- **Given** more than one master record matches a related public identifier
- **When** a query attempts to enrich a response
- **Then** the API returns generic `500 INTERNAL_SERVER_ERROR`
- **And** it does not choose one master row

