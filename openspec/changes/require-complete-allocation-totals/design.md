# Design: Complete Allocation Totals

## Context

The baseline validates every allocation percentage independently as a decimal string between `0.00` and `100.00`. It does not evaluate the sum across the order. The new rule must be exact, deterministic, reusable by create, replacement, submission, and fixture validation, and safe for deliberately malformed stored data.

## Decision

Convert each already validated percentage into integer basis points, where `100.00` becomes `10000`, and sum the integers. A valid complete order has a sum of exactly `10000` basis points.

Binary floating-point arithmetic, epsilon tolerances, and rounded post-sums are prohibited. The accepted two-decimal API precision makes basis points the complete domain representation rather than an approximation.

## Validation algorithm

For each allocation percentage:

1. Require the existing accepted decimal-string syntax with no more than two decimal places.
2. Canonicalize the string to two decimal places.
3. Convert whole and fractional digits to a non-negative integer basis-point value.
4. Enforce the existing individual range `0` through `10000` basis points.

Only when every allocation has a valid individual percentage does the service sum the basis-point values. If the sum differs from `10000`, it emits one order-level violation:

| Field | Value |
|---|---|
| HTTP status | `422` |
| Problem code | `INVALID_ALLOCATION_TOTAL` |
| Violation path | `/allocations` |
| Expected | `100.00` |
| Actual | canonical two-decimal sum, such as `90.00` or `110.00` |

The aggregate check runs after duplicate-strategy and individual-percentage checks but before the client-order-reference conflict query and before any mutation. If one or more individual percentages are invalid, the aggregate check is skipped; the caller receives the independently meaningful `INVALID_ALLOCATION_PERCENTAGE` violation instead of a derived or misleading total.

## Operation behavior

| Operation | Aggregate validation |
|---|---|
| `OP-ALLOC-CREATE-001` | Required before allocating an ID or writing rows. |
| `OP-ALLOC-UPDATE-001` | Required before replacing header or allocation rows. |
| `OP-ALLOC-SUBMIT-001` | Required while revalidating the stored draft. |
| `OP-ALLOC-GET-001` | Not run; returns stored data without repair. |
| `OP-ALLOC-CANCEL-001` | Not run; invalid stored content must remain cancellable. |

Every failed create or replacement leaves the database and identifier sequence unchanged. Failed submission leaves the order in `DRAFT` and does not update its audit timestamp.

## OpenAPI changes

- Add `INVALID_ALLOCATION_TOTAL` to the `ErrorCode` enum.
- Add the code to `x-error-codes` for create, replace, and submit.
- Clarify allocation request descriptions without encoding a cross-item sum in JSON Schema.
- Add a `422` example for a `90.00` total.
- Retain the existing percentage string schema and response shapes.
- Advance the API contract version as a backward-incompatible behavioral revision according to project release policy.

The total is application-level validation because OpenAPI 3.0/JSON Schema cannot express an exact sum across array item values represented as decimal strings.

## Fixture behavior

The current baseline dataset already contains totals of `100.00`, so it needs no value changes. After this change, the fixture validator adds issue code `INVALID_ALLOCATION_TOTAL` and applies the same basis-point function.

An adverse profile may intentionally store an incomplete total only when its `expectedDataIssues` declares the complete issue tuple. The database schema remains permissive and receives no `CHECK`, trigger, or migration that would prevent such a profile.

## Test and acceptance mapping

| Test ID | Scenario | Requirement link | Operation |
|---|---|---|---|
| `TC-ALLOC-TOTAL-001` | `60.00 + 40.00` is accepted | `AC-ALLOC-009-01` | Create |
| `TC-ALLOC-TOTAL-002` | `60.00 + 30.00` is rejected | `AC-ALLOC-009-02` | Create |
| `TC-ALLOC-TOTAL-003` | `60.00 + 50.00` is rejected | `AC-ALLOC-009-03` | Create |
| `TC-ALLOC-TOTAL-004` | Schema-valid `101.00` is reported as individually out of range | `AC-ALLOC-009-04` | Create |
| `TC-ALLOC-TOTAL-005` | Incomplete replacement rolls back | `AC-ALLOC-009-05` | Replace |
| `TC-ALLOC-TOTAL-006` | Incomplete stored draft cannot be submitted | `AC-ALLOC-009-06` | Submit |

`TC-ALLOC-TOTAL-002` is the pre-existing tester-authored case that motivated this change. Once the requirement delta is accepted, the knowledge layer can replace its orphan state with `AC-ALLOC-009-02 VERIFIED_BY TC-ALLOC-TOTAL-002` while retaining provenance to the original test artifact.

## Traceability

```text
CHG-ALLOC-TOTAL-001
  ADDS REQ-ALLOC-009
REQ-ALLOC-009
  HAS_ACCEPTANCE_CRITERION AC-ALLOC-009-01..06
AC-ALLOC-009-01..04
  APPLIES_TO OP-ALLOC-CREATE-001
AC-ALLOC-009-05
  APPLIES_TO OP-ALLOC-UPDATE-001
AC-ALLOC-009-06
  APPLIES_TO OP-ALLOC-SUBMIT-001
AC-ALLOC-009-01..06
  VERIFIED_BY TC-ALLOC-TOTAL-001..006
TASK-ALLOC-TOTAL-001..009
  IMPLEMENTS REQ-ALLOC-009
```

## Alternatives considered

### Decimal arithmetic package

Rejected because two-decimal percentage precision maps exactly to small integers; another runtime dependency adds no value.

### Floating-point sum with tolerance

Rejected because it introduces an arbitrary tolerance and makes boundary behavior harder to explain and reproduce.

### SQLite constraint or trigger

Rejected because a cross-row total is awkward to enforce and the database must continue to hold declared invalid test data.

### Automatically adjust the final allocation

Rejected because it changes caller intent and hides an invalid command.

## Rollback

Reverting the application and OpenAPI changes restores the prior behavior without a database migration. Any adverse profile added for this rule can remain unused or be removed independently. No stored business data is rewritten by deployment.
