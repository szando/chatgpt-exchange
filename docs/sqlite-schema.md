# SQLite Schema Design

## Purpose

The mock API uses SQLite as a real, queryable source of portfolio data rather
than selecting preprogrammed responses. The baseline fixture profile contains
contract-compliant data, while adverse profiles may deliberately contain
missing relationships, malformed values or inconsistent records so the PPM API
TDK can exercise schema and data-quality checks.

The schema is defined by `data/schema/001-initial-schema.sql` and requires the
`node:sqlite` module supplied by Node.js 24.

## Validation boundary

SQLite is a storage mechanism, not the first line of business validation.

| Layer | Responsibility |
|---|---|
| SQLite | Preserve selected fixture values and API mutations |
| Fixture validator | Detect accidental defects and verify declared adverse defects |
| Application service | Validate allocation-order commands and transitions |
| Response mapper | Enrich stored records without silently repairing them |
| PPM API TDK | Detect contract, schema and data-quality failures in responses |

Business-data tables therefore have:

- An internal `row_id` primary key.
- No foreign-key constraints.
- No `CHECK` constraints for enums, dates, decimals, states or percentages.
- No uniqueness constraints on public domain identifiers.
- No database-level uniqueness constraint for client order references.
- `ANY` columns for contract-visible values.

Internal control tables are stricter because they are not test-domain data:

- `schema_metadata` identifies the installed schema.
- `dataset_metadata` identifies the selected fixture profile and related seed information.
- `id_sequences` controls deterministic server-generated identifiers.

## Why `STRICT` and `ANY` are used together

SQLite `STRICT` tables make the physical schema explicit. Within those tables,
the `ANY` datatype preserves the storage class of a supplied value rather than
coercing it to the declared affinity.

For example, a baseline quantity can be stored as the string `"250.0000"`,
while an adverse profile can intentionally store the number `250`. The API can
then return the number without SQLite first converting it into a contract-valid
string.

## Logical table model

| Table | Purpose |
|---|---|
| `portfolios` | Portfolio master data |
| `instruments` | Instrument reference data |
| `strategies` | Strategy reference and classification data |
| `portfolio_strategies` | Portfolio-to-strategy availability relationships |
| `positions` | Dated position and valuation snapshots |
| `transactions` | Booked portfolio transactions |
| `performance_records` | Daily and monthly portfolio performance |
| `allocation_orders` | Allocation-order headers and lifecycle state |
| `allocation_order_allocations` | Ordered strategy allocations belonging to an order |

Nested API response elements are assembled through joins. They are not stored
as duplicated JSON documents. For example, a position contains `portfolioId`
and `instrumentId`, while the corresponding portfolio and instrument summaries
are obtained from the master-data tables.

## Missing and inconsistent relationships

Because foreign keys are deliberately absent, an adverse profile can contain a
position whose `instrument_id` has no matching instrument. The position remains
queryable. Its top-level `instrumentId` is returned, while the unavailable
nested `instrument` summary is omitted. This intentionally violates the
baseline OpenAPI response schema and allows the TDK to detect the defect.

The same principle applies to other relationships. The API must not create a
fictional related resource merely to make a response schema-valid.

## Identifier uniqueness

Public identifiers are indexed but not declared unique. The baseline fixture
validator requires them to be unique. An adverse profile may deliberately
violate that rule.

Repository methods must therefore never rely on an unspecified SQLite row
order. Resource lookups order matching rows by `row_id`. The implementation
design will define how a resource-oriented operation responds when more than
one row has the requested public identifier.

## Client order reference uniqueness

The rule that `clientOrderReference` is unique within a portfolio is enforced
by the allocation-order application service inside the same transaction as the
insert or replacement. It is intentionally not a unique database constraint.
This allows adverse fixtures to contain pre-existing duplicates.

## Deterministic allocation-order identifiers

The baseline seed initializes `id_sequences` with:

```text
sequence_name: allocation_order
next_numeric_value: 5004
```

Creating the first order after a clean reset therefore produces `AORD-5004`.
Identifier allocation and insertion must occur within one SQLite transaction.

## Fixed ordering

Indexes support the documented query order, but every repository query must
still contain an explicit `ORDER BY` clause:

| Query | Required order |
|---|---|
| Positions | `as_of_date`, `portfolio_id`, `instrument_id`, `row_id` ascending |
| Transactions | `booking_date` descending, `transaction_id`, `row_id` ascending |
| Strategies | `strategy_name`, `strategy_id`, `row_id` ascending |
| Performance | `period_start`, `performance_id`, `row_id` ascending |
| Order allocations | `sequence_number`, `row_id` ascending |

The final `row_id` tie-breaker guarantees deterministic ordering even when an
adverse profile contains duplicate business identifiers.

## Database lifecycle

For an automated TDK run, Vitest creates a temporary database, applies the
schema, seeds the selected fixture profile, starts the API with that database
path, and removes the database after the API process stops.

For manual use, the container may use a file-backed database in a mounted
volume. An existing database is never silently reseeded.

The application reads the database location from:

```text
MOCK_API_DATABASE_PATH
```

Startup fails when the database schema version is unsupported. The readiness
endpoint reports `NOT_READY` when the configured database cannot be opened or
queried.

## Schema migration rules

Schema migrations are applied in numeric filename order. Each migration:

- Runs inside an explicit transaction.
- Updates both `PRAGMA user_version` and `schema_metadata`.
- Is applied only once.
- Fails startup rather than attempting automatic repair when partially or
  unexpectedly applied.

The initial schema sets both version markers to `1`.
