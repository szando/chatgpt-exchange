# OpenSpec Package Guide

## Current state

`openspec/specs/` is the authoritative behavioral baseline. It describes the accepted initial mock API and contains only the currently approved rules.

`openspec/changes/archive/2026-08-17-build-portfolio-demo-api/` preserves the completed change that established that baseline. Its delta specifications use `## ADDED Requirements` and correspond to the applied capability specifications.

`openspec/changes/require-complete-allocation-totals/` is an active proposed change. Its delta is not yet part of the current baseline. Applying it will add `REQ-ALLOC-009` and its six acceptance criteria to the `allocation-orders` capability.

## Authority and update flow

1. Review a change's `proposal.md` to agree on the business outcome and scope.
2. Review its delta under `specs/` to agree on observable behavior.
3. Review `design.md` for technical decisions and traceability.
4. Execute and check off `tasks.md` during implementation.
5. Verify the complete change against the OpenAPI contract and serialized HTTP responses.
6. Apply the delta to `openspec/specs/` only after acceptance.
7. Archive the completed change beneath a date-prefixed archive directory.

The active delta must not be copied into the baseline early. Until the change is implemented and accepted, agents should report the aggregate rule as proposed and implementation as planned or in progress—not complete.

## Stable identifiers

| Prefix | Meaning | Example |
|---|---|---|
| `CHG-` | OpenSpec change | `CHG-ALLOC-TOTAL-001` |
| `REQ-` | Business requirement | `REQ-ALLOC-009` |
| `AC-` | Acceptance criterion | `AC-ALLOC-009-02` |
| `OP-` | API operation trace identifier | `OP-ALLOC-CREATE-001` |
| `TC-` | Test case | `TC-ALLOC-TOTAL-002` |
| `TASK-` | Implementation task | `TASK-ALLOC-TOTAL-006` |
| `SYS-` | Cross-cutting system requirement | `SYS-DATA-001` |

Identifiers are never reused. Renaming prose does not change an identifier. A relationship must preserve provenance to the source file in which the identifier is authoritative.

## Baseline capabilities

| Capability | Main responsibility |
|---|---|
| `portfolio-retrieval` | Direct GET retrieval of a portfolio. |
| `portfolio-queries` | Four POST-based filtered read operations and fixed sorting. |
| `allocation-orders` | Create, get, replace, submit, cancel, and baseline validation. |
| `error-handling` | Problem Details, adverse response preservation, and ambiguity policy. |
| `service-operation` | Health, readiness, startup, fixed time, and offline runtime. |

## Validation

The package follows the default spec-driven artifact sequence and standard Markdown markers:

```text
proposal.md
specs/<capability>/spec.md
design.md
tasks.md
```

Requirements use `### Requirement:` and normative `MUST` language. Scenarios use `#### Scenario:` with Given/When/Then steps. Delta specifications use `## ADDED Requirements`; no custom OpenSpec schema is required.

Before implementation handoff, validate at least these invariants:

- every requirement has one or more scenarios;
- every OpenAPI trace requirement and acceptance criterion appears in the baseline specs;
- the active `REQ-ALLOC-009` rule appears only in the active change until applied;
- all archived tasks are checked and all proposed implementation tasks are initially unchecked; and
- generated OpenAPI/type artifacts are not treated as behavioral authority over the current specs.

## OpenSpec references

- [OpenSpec repository](https://github.com/Fission-AI/OpenSpec) — https://github.com/Fission-AI/OpenSpec
- [OpenSpec core concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md) — https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md
- [OpenSpec customization](https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md) — https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md
