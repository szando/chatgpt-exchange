# Tasks: Require Complete Allocation Totals

## Contract and traceability

- [ ] `TASK-ALLOC-TOTAL-001` Add `REQ-ALLOC-009` and `AC-ALLOC-009-01` through `AC-ALLOC-009-06` to authoritative requirement and traceability sources.
- [ ] `TASK-ALLOC-TOTAL-002` Link existing `TC-ALLOC-TOTAL-002` to `AC-ALLOC-009-02` while preserving its original test provenance.
- [ ] `TASK-ALLOC-TOTAL-003` Add `INVALID_ALLOCATION_TOTAL` to OpenAPI and document it for create, replace, and submit with a `90.00` example.
- [ ] `TASK-ALLOC-TOTAL-004` Regenerate request schemas/types and verify that generated output is otherwise unchanged.

## Domain and application behavior

- [ ] `TASK-ALLOC-TOTAL-005` Implement the shared decimal-string-to-basis-points conversion and exact aggregate validator without floating-point arithmetic.
- [ ] `TASK-ALLOC-TOTAL-006` Invoke the validator after individual percentage validation in create, replace, and submit workflows.
- [ ] `TASK-ALLOC-TOTAL-007` Map aggregate failures to one `422 INVALID_ALLOCATION_TOTAL` Problem Details violation at `/allocations`.
- [ ] `TASK-ALLOC-TOTAL-008` Extend fixture validation and expected-issue vocabulary while leaving SQLite constraints unchanged.
- [ ] `TASK-ALLOC-TOTAL-009` Add an optional declared adverse fixture containing an incomplete stored allocation total.

## Verification

- [ ] `TASK-ALLOC-TOTAL-010` Add unit coverage for exact, below, above, zero-entry contribution, `0.01` boundary, `99.99 + 0.01`, and canonical output values.
- [ ] `TASK-ALLOC-TOTAL-011` Implement `TC-ALLOC-TOTAL-001` through `TC-ALLOC-TOTAL-004` against create.
- [ ] `TASK-ALLOC-TOTAL-012` Implement `TC-ALLOC-TOTAL-005` and prove replacement and sequence state roll back completely.
- [ ] `TASK-ALLOC-TOTAL-013` Implement `TC-ALLOC-TOTAL-006` and prove rejected submission leaves status and audit time unchanged.
- [ ] `TASK-ALLOC-TOTAL-014` Prove GET still exposes an incomplete stored total and cancellation still succeeds for that order.
- [ ] `TASK-ALLOC-TOTAL-015` Run the full baseline contract, lifecycle, fixture, adverse-profile, Windows, Linux, and offline-container suites.

## Completion

- [ ] `TASK-ALLOC-TOTAL-016` Apply the accepted delta to `openspec/specs/allocation-orders/spec.md` only after implementation and verification are complete.
- [ ] `TASK-ALLOC-TOTAL-017` Archive this change with its final evidence and ensure no active task remains unchecked.

