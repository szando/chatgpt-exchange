# Portfolio Retrieval

## Purpose

Defines direct retrieval of a fictional portfolio through the API's simple GET operation.

## ADDED Requirements

### Requirement: REQ-PORT-001 — Retrieve a portfolio by identifier

The API MUST expose `GET /api/v1/portfolios/{portfolioId}` as operation `OP-PORT-GET-001`. A successful response MUST contain the stored portfolio identifier, name, portfolio type, base currency, status, and valuation date.

#### Scenario: AC-PORT-001-01 — Existing portfolio is returned

- **Given** exactly one stored portfolio has identifier `PORT-1001`
- **When** the client requests `GET /api/v1/portfolios/PORT-1001`
- **Then** the API returns `200 OK`
- **And** the response represents that stored portfolio

#### Scenario: AC-PORT-001-02 — Missing portfolio is reported

- **Given** no stored portfolio has identifier `PORT-9999`
- **When** the client requests `GET /api/v1/portfolios/PORT-9999`
- **Then** the API returns `404 Not Found`
- **And** the Problem Details code is `PORTFOLIO_NOT_FOUND`

#### Scenario: Invalid portfolio identifier is rejected

- **Given** a portfolio identifier does not match `PORT-[0-9]{4}`
- **When** the client uses it in the portfolio path
- **Then** the API returns `400 Bad Request`
- **And** the Problem Details code is `INVALID_IDENTIFIER_FORMAT`

