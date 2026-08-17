# Allocation Orders

## Purpose

Defines creation, retrieval, replacement, submission, and cancellation of allocation orders in the accepted baseline system.

## ADDED Requirements

### Requirement: REQ-ALLOC-001 — Create a draft allocation order

The API MUST expose `POST /api/v1/allocation-orders` as `OP-ALLOC-CREATE-001`. A valid request MUST create one allocation order with at least one allocation and return `201 Created` with its resource location.

#### Scenario: AC-ALLOC-001-01 — Valid order is created

- **Given** all referenced active records exist and the command satisfies baseline business validation
- **When** the client creates an allocation order
- **Then** the API returns `201 Created`
- **And** exactly one order and its allocations are persisted atomically

#### Scenario: AC-ALLOC-001-02 — Response is enriched

- **When** an allocation order is returned
- **Then** it includes nested portfolio, instrument, strategy, order-details, allocation, and audit information when referenced masters exist exactly once

#### Scenario: AC-ALLOC-001-03 — Identifier is allocated deterministically

- **Given** the clean baseline sequence has next value `5004`
- **When** the first order is created
- **Then** its identifier is `AORD-5004`

#### Scenario: AC-ALLOC-001-04 — New order is draft

- **When** an allocation order is created
- **Then** its status is `DRAFT`

#### Scenario: AC-ALLOC-001-05 — Audit timestamps use the service clock

- **When** an allocation order is created
- **Then** `createdAt` and `updatedAt` use the same injected clock instant

#### Scenario: AC-ALLOC-001-06 — Location identifies the resource

- **When** allocation order `AORD-5004` is created
- **Then** the `Location` header is `/api/v1/allocation-orders/AORD-5004`

#### Scenario: AC-ALLOC-001-07 — At least one allocation is required

- **When** a create request has no allocations
- **Then** the API returns `400 Bad Request`
- **And** the Problem Details code is `INVALID_REQUEST`

#### Scenario: AC-ALLOC-001-08 — Valid decimals are canonicalized

- **When** a valid order is written
- **Then** quantities are stored and returned with four decimal places
- **And** allocation percentages are stored and returned with two decimal places

### Requirement: REQ-ALLOC-002 — Validate referenced business records

Create, replace, and submit operations MUST require exactly one referenced portfolio, instrument, and strategy record; require each to be active; require every strategy to be available to the order's portfolio; and reject duplicate strategies within one order.

#### Scenario: Unknown or inactive reference is rejected

- **Given** a referenced master is missing or inactive
- **When** a validating allocation-order operation is requested
- **Then** the API returns `422 Unprocessable Content`
- **And** it reports the corresponding stable reference error code

#### Scenario: Unavailable strategy is rejected

- **Given** an active strategy is not available to the selected portfolio
- **When** a validating operation is requested
- **Then** the API reports `STRATEGY_NOT_AVAILABLE`

#### Scenario: Duplicate strategy is rejected

- **Given** two allocation entries use the same strategy identifier
- **When** a validating operation is requested
- **Then** the API reports `DUPLICATE_STRATEGY`

### Requirement: REQ-ALLOC-003 — Validate individual quantities and percentages

Create, replace, and submit operations MUST require a positive quantity with at most four decimal places and MUST validate each allocation percentage independently as a decimal string between `0.00` and `100.00`, inclusive, with at most two decimal places.

#### Scenario: Invalid quantity is rejected

- **Given** quantity has a schema-valid decimal representation
- **When** its numeric value is zero
- **Then** the API returns `422 Unprocessable Content`
- **And** it reports `INVALID_QUANTITY`

#### Scenario: Invalid quantity representation is rejected at the boundary

- **When** quantity is negative, malformed, or has more than four decimal places
- **Then** request-schema validation returns `400 Bad Request`
- **And** the Problem Details code is `INVALID_REQUEST`

#### Scenario: Individually valid allocation is accepted by percentage validation

- **Given** an allocation percentage is `60.00`
- **When** that allocation entry is validated
- **Then** it passes individual percentage validation

#### Scenario: Individually invalid allocation is rejected

- **Given** an allocation percentage has a schema-valid decimal representation
- **When** it is outside `0.00` through `100.00`
- **Then** the API reports `INVALID_ALLOCATION_PERCENTAGE`

#### Scenario: Invalid percentage representation is rejected at the boundary

- **When** an allocation percentage is malformed or has more than two decimal places
- **Then** request-schema validation returns `400 Bad Request`
- **And** the Problem Details code is `INVALID_REQUEST`

### Requirement: REQ-ALLOC-004 — Retrieve a stored order without repair

The API MUST expose `GET /api/v1/allocation-orders/{allocationOrderId}` as `OP-ALLOC-GET-001` and MUST return the stored order without rerunning write validation or repairing adverse fixture values.

#### Scenario: AC-ALLOC-001-09 — Existing order is returned as stored

- **Given** exactly one order has the requested identifier
- **When** it is retrieved
- **Then** the API returns `200 OK`
- **And** stored contract-visible defects remain observable

#### Scenario: Missing order is reported

- **Given** no order has the requested identifier
- **When** it is retrieved
- **Then** the API returns `404 Not Found`
- **And** the code is `ALLOCATION_ORDER_NOT_FOUND`

### Requirement: REQ-ALLOC-005 — Replace editable fields of a draft

The API MUST expose `PUT /api/v1/allocation-orders/{allocationOrderId}` as `OP-ALLOC-UPDATE-001`. It MUST replace all editable fields and allocation entries atomically, and it MUST permit replacement only while the order is `DRAFT`.

#### Scenario: AC-ALLOC-005-01 — Draft is completely replaced

- **Given** an allocation order is `DRAFT`
- **When** a valid replacement is submitted
- **Then** all editable header fields and allocations equal the replacement request
- **And** the operation returns `200 OK`

#### Scenario: AC-ALLOC-005-02 — Non-draft is not editable

- **Given** an allocation order is `SUBMITTED` or `CANCELLED`
- **When** replacement is attempted
- **Then** the API returns `409 Conflict`
- **And** the code is `ALLOCATION_ORDER_NOT_EDITABLE`

#### Scenario: AC-ALLOC-005-03 — Failed replacement rolls back

- **When** any replacement write or validation step fails
- **Then** neither header fields nor allocation rows are partially changed

### Requirement: REQ-ALLOC-006 — Submit a valid draft

The API MUST expose `POST /api/v1/allocation-orders/{allocationOrderId}/submit` as `OP-ALLOC-SUBMIT-001`. It MUST permit submission only from `DRAFT` and MUST revalidate the current stored order before setting status to `SUBMITTED`.

#### Scenario: AC-ALLOC-006-01 — Valid draft is submitted

- **Given** a stored draft satisfies current write rules
- **When** it is submitted
- **Then** its status becomes `SUBMITTED`
- **And** the API returns `200 OK`

#### Scenario: AC-ALLOC-006-02 — Wrong state is not submittable

- **Given** an order is `SUBMITTED` or `CANCELLED`
- **When** submission is requested
- **Then** the API returns `409 Conflict`
- **And** the code is `ALLOCATION_ORDER_NOT_SUBMITTABLE`

### Requirement: REQ-ALLOC-007 — Cancel without content revalidation

The API MUST expose `POST /api/v1/allocation-orders/{allocationOrderId}/cancel` as `OP-ALLOC-CANCEL-001`. It MUST permit cancellation from `DRAFT` or `SUBMITTED`, MUST set status to `CANCELLED`, and MUST NOT revalidate allocation content.

#### Scenario: AC-ALLOC-007-01 — Draft is cancelled

- **Given** an order is `DRAFT`
- **When** cancellation is requested
- **Then** its status becomes `CANCELLED`

#### Scenario: AC-ALLOC-007-02 — Submitted order is cancelled

- **Given** an order is `SUBMITTED`
- **When** cancellation is requested
- **Then** its status becomes `CANCELLED`

#### Scenario: AC-ALLOC-007-03 — Cancelled order cannot be cancelled again

- **Given** an order is `CANCELLED`
- **When** cancellation is requested
- **Then** the API returns `409 Conflict`
- **And** the code is `ALLOCATION_ORDER_NOT_CANCELLABLE`

### Requirement: REQ-ALLOC-008 — Scope client reference uniqueness to a portfolio

The API MUST require `clientOrderReference` to be unique among allocation orders for the same portfolio. Replacement MUST exclude the order being replaced from the conflict check.

#### Scenario: AC-ALLOC-008-01 — Duplicate reference in one portfolio conflicts

- **Given** an order already uses a client reference in a portfolio
- **When** another order is created with the same reference and portfolio
- **Then** the API returns `409 Conflict`
- **And** the code is `CLIENT_ORDER_REFERENCE_CONFLICT`

#### Scenario: AC-ALLOC-008-02 — Same reference in another portfolio is allowed

- **Given** a client reference exists in one portfolio
- **When** a valid order uses it in a different portfolio
- **Then** the reference does not cause a conflict

#### Scenario: AC-ALLOC-008-03 — Replacement may retain its reference

- **Given** a draft order retains its own client reference
- **When** it is validly replaced
- **Then** it does not conflict with itself

#### Scenario: AC-ALLOC-008-04 — Replacement cannot adopt a sibling reference

- **Given** another order in the same portfolio uses the requested reference
- **When** a draft replacement attempts to use it
- **Then** the API returns `409 Conflict`
