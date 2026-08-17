# Portfolio Data Queries

## Purpose

Defines the four POST-based read operations for positions, transactions, strategies, and performance.

## Requirements

### Requirement: REQ-QUERY-001 — Query through JSON request bodies

The API MUST expose position, transaction, strategy, and performance reads as JSON `POST` query operations under `/api/v1`. Except for the strategy query, a request MUST contain at least one supported filter.

#### Scenario: Query request supplies a supported filter

- **Given** a client sends `Content-Type: application/json`
- **And** the request body contains at least one filter supported by the selected operation
- **When** the query is processed
- **Then** the API evaluates the request against stored data

#### Scenario: Required query filter is absent

- **Given** an operation other than the strategy query requires at least one filter
- **When** the client submits an empty JSON object
- **Then** the API returns `400 Bad Request`
- **And** the Problem Details code is `MISSING_QUERY_FILTER`

### Requirement: REQ-QUERY-002 — Combine filters predictably

The API MUST combine different supplied filter fields with logical AND. Within an identifier or enum array, a record MUST match any listed value.

#### Scenario: Multiple filters narrow a result

- **Given** a query supplies a portfolio filter and a second supported filter
- **When** records are selected
- **Then** every returned record satisfies both filter fields
- **And** an array-valued filter accepts any value contained in that array

### Requirement: REQ-QUERY-003 — Return a fixed response envelope and order

Every successful query MUST return an object containing `items` and `totalCount`. The API MUST use its documented fixed sorting and MUST NOT accept a client sorting parameter.

#### Scenario: Matching records are returned deterministically

- **Given** multiple records match a query
- **When** the query is repeated against unchanged data
- **Then** `items` is returned in the same documented order
- **And** `totalCount` equals the number of returned items

### Requirement: REQ-QUERY-004 — Return an empty successful result

A valid query with no matches MUST return `200 OK` with `items: []` and `totalCount: 0`.

#### Scenario: Valid filter has no matches

- **Given** the request is structurally and semantically valid
- **And** no stored record satisfies it
- **When** the query is processed
- **Then** the response is `200 OK`
- **And** the result envelope is empty rather than an error

### Requirement: REQ-POS-001 — Query position snapshots

The API MUST expose `POST /api/v1/positions/query` as `OP-POS-QUERY-001`. It MUST filter by any supplied `portfolioIds`, `instrumentIds`, and exact `asOfDate`; return nested portfolio, instrument, and valuation details; and sort by `asOfDate`, `portfolioId`, `instrumentId`, and storage row identifier ascending.

#### Scenario: AC-POS-001-01 — Positions are filtered by portfolio

- **Given** position snapshots exist for more than one portfolio
- **When** `portfolioIds` contains `PORT-1001`
- **Then** every returned position has `portfolioId` equal to `PORT-1001`

#### Scenario: AC-POS-001-02 — Positions are filtered by instrument

- **Given** multiple instruments have position snapshots
- **When** `instrumentIds` contains one instrument identifier
- **Then** every returned position refers to one of the requested instruments

#### Scenario: AC-POS-001-03 — Position date is exact

- **When** `asOfDate` is supplied
- **Then** every returned valuation has that exact `asOfDate`

#### Scenario: AC-POS-001-04 — Position response is enriched

- **Given** referenced portfolio and instrument records exist exactly once
- **When** a position is returned
- **Then** it includes nested `portfolio`, `instrument`, and `valuation` objects

#### Scenario: AC-POS-001-05 — Position order is fixed

- **When** multiple positions match
- **Then** they are sorted by `asOfDate`, `portfolioId`, `instrumentId`, and row identifier ascending

### Requirement: REQ-TXN-001 — Query transactions

The API MUST expose `POST /api/v1/transactions/query` as `OP-TXN-QUERY-001`. It MUST support `portfolioIds`, `transactionTypes`, and inclusive `bookingDateFrom` and `bookingDateTo` filters; return nested dates, amount, and available portfolio and instrument summaries; and sort by booking date descending, then transaction identifier and row identifier ascending.

#### Scenario: AC-TXN-001-01 — Transactions are filtered

- **Given** transaction records exist across portfolios and types
- **When** portfolio and transaction-type filters are supplied
- **Then** every returned transaction matches both filters

#### Scenario: AC-TXN-001-02 — Booking-date bounds are inclusive

- **When** a booking-date range is supplied
- **Then** records on either boundary are eligible to be returned

#### Scenario: AC-TXN-001-03 — Invalid booking-date range is rejected

- **Given** `bookingDateFrom` is later than `bookingDateTo`
- **When** the query is processed
- **Then** the API returns `422 Unprocessable Content`
- **And** the Problem Details code is `INVALID_BOOKING_DATE_RANGE`

#### Scenario: AC-TXN-001-04 — Transaction response is nested

- **When** a matching transaction is returned
- **Then** it contains `dates` and `details`
- **And** it contains the corresponding nested master summaries when those masters exist exactly once

#### Scenario: AC-TXN-001-05 — Transaction order is fixed

- **When** multiple transactions match
- **Then** booking date is descending
- **And** transaction identifier and row identifier are ascending tie-breakers

### Requirement: REQ-STRAT-001 — Query strategies

The API MUST expose `POST /api/v1/strategies/query` as `OP-STRAT-QUERY-001`. It MUST support optional `portfolioIds`, `strategyIds`, and `activeOnly` filters, default `activeOnly` to `true`, include profile and availability details, and sort by strategy name, strategy identifier, and row identifier ascending.

#### Scenario: AC-STRAT-001-01 — Empty request returns active strategies

- **When** the client submits `{}`
- **Then** the API treats `activeOnly` as `true`
- **And** only active strategies are returned

#### Scenario: AC-STRAT-001-02 — Portfolio availability filters strategies

- **When** `portfolioIds` is supplied
- **Then** every returned strategy is available to at least one requested portfolio

#### Scenario: AC-STRAT-001-03 — Strategy order and nesting are fixed

- **When** multiple strategies match
- **Then** they are sorted by strategy name, strategy identifier, and row identifier ascending
- **And** each item contains nested `profile` and `availability` objects

### Requirement: REQ-PERF-001 — Query performance records

The API MUST expose `POST /api/v1/performance/query` as `OP-PERF-QUERY-001`. It MUST support `portfolioIds`, inclusive `periodFrom` and `periodTo` overlap bounds, and `granularity`; return nested portfolio, period, and returns details; and sort by period start, performance identifier, and row identifier ascending.

#### Scenario: AC-PERF-001-01 — Performance records are filtered by portfolio

- **When** `portfolioIds` is supplied
- **Then** every returned record belongs to a requested portfolio

#### Scenario: AC-PERF-001-02 — Performance period filter is inclusive

- **When** a valid period range is supplied
- **Then** records whose documented performance period overlaps the inclusive requested bounds are eligible

#### Scenario: AC-PERF-001-03 — Invalid performance period is rejected

- **Given** `periodFrom` is later than `periodTo`
- **When** the query is processed
- **Then** the API returns `422 Unprocessable Content`
- **And** the Problem Details code is `INVALID_PERFORMANCE_PERIOD`

#### Scenario: AC-PERF-001-04 — Performance response is nested

- **When** a performance record is returned
- **Then** it contains nested `portfolio`, `period`, and `returns` objects when the referenced portfolio exists exactly once

#### Scenario: AC-PERF-001-05 — Performance order is fixed

- **When** multiple records match
- **Then** they are sorted by period start, performance identifier, and row identifier ascending
