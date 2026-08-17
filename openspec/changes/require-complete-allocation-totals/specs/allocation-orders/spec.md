# Allocation Orders Delta

## ADDED Requirements

### Requirement: REQ-ALLOC-009 — Require a complete allocation total

For every create, replacement, and submission validation, the API MUST require the sum of all individually valid allocation percentages to equal exactly `100.00`. It MUST calculate the sum as integer basis points and MUST NOT use binary floating-point tolerance or automatically adjust an allocation.

#### Scenario: AC-ALLOC-009-01 — Exact total is accepted

- **Given** an otherwise valid order contains percentages `60.00` and `40.00`
- **When** create validation is performed
- **Then** aggregate percentage validation succeeds
- **And** the operation may proceed

#### Scenario: AC-ALLOC-009-02 — Total below one hundred is rejected

- **Given** an otherwise valid order contains percentages `60.00` and `30.00`
- **When** create validation is performed
- **Then** the API returns `422 Unprocessable Content`
- **And** the Problem Details code is `INVALID_ALLOCATION_TOTAL`
- **And** one violation identifies `/allocations`, expected `100.00`, and actual `90.00`

#### Scenario: AC-ALLOC-009-03 — Total above one hundred is rejected

- **Given** an otherwise valid order contains percentages `60.00` and `50.00`
- **When** create validation is performed
- **Then** the API returns `422 Unprocessable Content`
- **And** the Problem Details code is `INVALID_ALLOCATION_TOTAL`
- **And** one violation identifies actual total `110.00`

#### Scenario: AC-ALLOC-009-04 — Individual invalidity is reported independently

- **Given** an allocation percentage has a schema-valid representation but is outside `0.00` through `100.00`
- **When** validation is performed
- **Then** the API reports `INVALID_ALLOCATION_PERCENTAGE`
- **And** it skips the aggregate-total check

#### Scenario: AC-ALLOC-009-05 — Incomplete replacement is rejected atomically

- **Given** a stored order is `DRAFT`
- **When** a replacement whose individually valid percentages do not total `100.00` is submitted
- **Then** the API returns `422 INVALID_ALLOCATION_TOTAL`
- **And** no header, allocation row, audit timestamp, or sequence value changes

#### Scenario: AC-ALLOC-009-06 — Incomplete stored draft cannot be submitted

- **Given** a stored `DRAFT` order has individually valid allocations totaling other than `100.00`
- **When** submission revalidation is performed
- **Then** the API returns `422 INVALID_ALLOCATION_TOTAL`
- **And** the order remains `DRAFT`
- **And** its audit timestamp remains unchanged
