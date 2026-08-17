# Change Proposal: Require Complete Allocation Totals

Change ID: `CHG-ALLOC-TOTAL-001`  
Status: Proposed

## Why

Tester-authored test `TC-ALLOC-TOTAL-002` demonstrates that an allocation order containing `60.00%` and `30.00%` allocations is currently accepted even though only `90.00%` of the order is allocated. Each entry satisfies the existing individual range rule, but the order is not completely allocated.

The test was initially linked to allocation-order creation operation `OP-ALLOC-CREATE-001` but had no acceptance-criterion link. Business review confirms that complete allocation is required, so the behavior must now become an authoritative requirement and the existing test must be linked to it.

## What changes

- Add requirement `REQ-ALLOC-009`: all allocation percentages across a validating order operation must total exactly `100.00`.
- Add acceptance criteria for exact, below-total, above-total, and individually invalid cases.
- Apply the rule to create, complete replacement, and submission revalidation.
- Add stable error code `INVALID_ALLOCATION_TOTAL` using `422 Unprocessable Content`.
- Keep retrieval and cancellation free from content revalidation.
- Calculate totals as integer basis points, never binary floating point.
- Link the previously orphaned test to the new acceptance criterion.

## Capabilities

### New capabilities

None.

### Modified capabilities

- `allocation-orders` — adds whole-order percentage validation.

## Compatibility impact

This is an intentional behavioral tightening. Requests previously accepted when every individual percentage was valid but the total differed from `100.00` will now receive `422`. The request and success-response shapes do not change.

Stored historical or adverse orders are not migrated or repaired. Retrieval and cancellation remain possible. Submission of a non-compliant stored draft is rejected during the existing revalidation step.

## Affected artifacts

- `openapi/portfolio-api.yaml`
- `src/domain/allocation-validation.ts`
- allocation-order application service
- fixture validator and profile issue vocabulary
- unit, API contract, repository integration, and adverse tests
- traceability records for `TC-ALLOC-TOTAL-001` through `TC-ALLOC-TOTAL-006`

## Out of scope

- Weighted allocation by quantity or market value.
- Rounding tolerances.
- Automatic balancing of the final allocation.
- Database constraints or data migration.
- Changing percentage precision beyond two decimal places.

