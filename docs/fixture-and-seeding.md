# Fixture Profiles and Deterministic Seeding

## Overview

The mock API obtains its responses from a SQLite database. Reviewable JSON
files define the baseline dataset, while derived adverse profiles apply small
SQL mutation scripts to the seeded baseline. No fixture profile changes API
control flow or introduces reserved identifiers with programmed behaviour.

The fixture format is described by `data/fixtures/profile-schema.json`.

## Directory structure

```text
data/fixtures/
├── profile-schema.json
├── baseline/
│   ├── profile.json
│   ├── id-sequences.txt
│   ├── portfolios.json
│   ├── instruments.json
│   ├── strategies.json
│   ├── portfolio-strategies.json
│   ├── positions.json
│   ├── transactions.json
│   ├── performance-records.json
│   └── allocation-orders.json
└── adverse/
    ├── missing-portfolio/
    │   ├── profile.json
    │   └── mutations.sql
    └── malformed-position/
        ├── profile.json
        └── mutations.sql
```

## Profile model

Every profile declares:

- `fixtureFormatVersion`: version of the profile format.
- `profileId`: stable lowercase identifier.
- `description`: human-readable purpose.
- `baseProfileId`: profile to seed first, or `null` for a root profile.
- `businessDate`: deterministic date represented by the profile.
- `sourceFiles`: JSON source files owned by the profile.
- `mutationScripts`: SQL scripts applied after source loading.
- `expectedDataIssues`: exact defects expected after seeding and mutation.

Version 1 supports only one level of inheritance: an adverse profile may extend
`baseline`, but profiles may not form longer chains. This prevents hidden or
circular fixture composition.

## Baseline load order

The seeder loads baseline files in this fixed order regardless of JSON object
property order:

1. `sequences`
2. `portfolios`
3. `instruments`
4. `strategies`
5. `portfolioStrategies`
6. `positions`
7. `transactions`
8. `performanceRecords`
9. `allocationOrders`
10. Nested allocation entries from each allocation order

Although SQLite does not enforce these relationships, the order makes the seed
process and diagnostics easy to follow.

## Mapping to SQLite

Fixture files use camelCase domain names. The seeder maps them explicitly to
snake_case database columns. It must not derive column names automatically.

Nested values are normalized during insertion:

| Fixture value | SQLite columns |
|---|---|
| `marketPrice` | `market_price_amount`, `market_price_currency` |
| `marketValue` | `market_value_amount`, `market_value_currency` |
| `netAmount` | `net_amount`, `net_amount_currency` |
| Allocation order `allocations` | Rows in `allocation_order_allocations` |

Missing optional JSON properties are inserted as SQLite `NULL`. Explicit JSON
`null` is preserved as `NULL`; the baseline avoids explicit nulls and uses
omission for optional response fields.

## Seed transaction

Creating a database follows this sequence:

1. Create a new database file.
2. Apply schema migrations in numeric order.
3. Start one seed transaction.
4. Resolve and load the base profile.
5. Load the selected profile's source files.
6. Apply mutation scripts in listed order.
7. Write `dataset_metadata`.
8. Run the fixture validator.
9. Compare actual issues with `expectedDataIssues`.
10. Commit only when the issue sets match exactly.

Any failure rolls back the entire seed transaction. A partially seeded database
must never be published to the API process.

## Dataset metadata

The seeder writes at least:

```text
profile_id
fixture_format_version
business_date
seeded_at
```

`seeded_at` uses the controlled clock when one is configured. It is diagnostic
metadata and does not appear in business responses.

## Fixture validation

The baseline validator checks structural and business-data quality without
changing stored values. Its checks include:

- Duplicate public identifiers.
- Missing portfolio, instrument, strategy or allocation-order references.
- Invalid identifier formats.
- Missing baseline response fields.
- Invalid enum values.
- Incorrect JSON/SQLite storage types.
- Invalid date and timestamp formats.
- Invalid money, quantity and percentage formats.
- Duplicate portfolio-to-strategy relationships.
- Duplicate strategies within an allocation order.
- Strategy availability and active-state consistency.
- Client-order-reference duplication within a portfolio.
- Allocation-order lifecycle values.

The fixture validator deliberately does not enforce that allocation percentages
sum to 100%. That invariant is absent from the baseline product requirement and
must not be smuggled into the system through fixture validation.

## Expected issue comparison

Issue comparison uses the complete tuple:

```text
code + entityType + rowId + field + value
```

`recordId` is descriptive and is not part of equality. Seeding fails when:

- An expected issue is not found.
- An undeclared issue is found.
- The same issue is reported more than once.

This keeps adverse profiles deliberate and reviewable.

## Mutation scripts

Mutation scripts operate only on a newly created temporary database inside the
seed transaction. They must not:

- Change schema objects.
- Change `schema_metadata`.
- Change `PRAGMA user_version`.
- Attach another database.
- Load SQLite extensions.
- Start or commit their own transaction.

The seeder rejects scripts containing schema-management, transaction-control,
attachment or extension-loading statements. Mutation scripts may insert,
update or delete business data and may update `id_sequences` when a profile
specifically requires it.

## Baseline guarantees

The baseline profile contains:

| Entity | Count |
|---|---:|
| Portfolios | 3 |
| Instruments | 4 |
| Strategies | 4 |
| Portfolio-strategy relationships | 6 |
| Positions | 4 |
| Transactions | 4 |
| Performance records | 5 |
| Allocation orders | 3 |
| Allocation entries | 5 |

It declares no expected data issues and initializes the allocation-order
sequence so the first created order is `AORD-5004`.

## Vitest usage

Each Vitest worker creates a unique temporary database path and selects a
fixture profile before starting the API process. Tests requiring different
profiles use independent database and API instances rather than mutating a
shared running database.

The intended configuration is:

```text
MOCK_API_DATABASE_PATH=<worker-specific path>
MOCK_API_FIXTURE_PROFILE=baseline
MOCK_API_FIXED_TIME=2026-08-14T09:30:00Z
```

The application process reads the completed database. It does not apply fixture
profiles or reseed an existing database during ordinary startup.
