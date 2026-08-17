-- Fictional Portfolio Management API
-- Initial SQLite schema, version 1
--
-- Business-data tables are deliberately permissive. They use surrogate row
-- keys, do not declare foreign keys, and do not enforce business constraints
-- or domain-identifier uniqueness. This allows adverse fixture profiles to
-- contain dangling references, duplicate identifiers, invalid enumerations,
-- malformed scalar values, and inconsistent financial data.
--
-- STRICT tables with ANY payload columns preserve the SQLite storage class of
-- fixture values instead of coercing them. A deliberately numeric quantity can
-- therefore remain numeric and produce an OpenAPI-invalid JSON response.

PRAGMA foreign_keys = OFF;

BEGIN IMMEDIATE;

CREATE TABLE schema_metadata (
    metadata_key   TEXT PRIMARY KEY,
    metadata_value TEXT NOT NULL
) STRICT;

INSERT INTO schema_metadata (metadata_key, metadata_value)
VALUES ('schema_version', '1');

CREATE TABLE dataset_metadata (
    metadata_key   TEXT PRIMARY KEY,
    metadata_value TEXT NOT NULL
) STRICT;

CREATE TABLE id_sequences (
    sequence_name     TEXT PRIMARY KEY,
    next_numeric_value INTEGER NOT NULL
) STRICT;

CREATE TABLE portfolios (
    row_id          INTEGER PRIMARY KEY,
    portfolio_id    ANY,
    name            ANY,
    portfolio_type  ANY,
    base_currency   ANY,
    status          ANY,
    valuation_date  ANY
) STRICT;

CREATE INDEX idx_portfolios_portfolio_id
    ON portfolios (portfolio_id);

CREATE TABLE instruments (
    row_id         INTEGER PRIMARY KEY,
    instrument_id  ANY,
    name           ANY,
    symbol         ANY,
    asset_class    ANY,
    currency       ANY,
    status         ANY
) STRICT;

CREATE INDEX idx_instruments_instrument_id
    ON instruments (instrument_id);

CREATE TABLE strategies (
    row_id            INTEGER PRIMARY KEY,
    strategy_id       ANY,
    strategy_name     ANY,
    description       ANY,
    status            ANY,
    objective         ANY,
    risk_level        ANY
) STRICT;

CREATE INDEX idx_strategies_strategy_id
    ON strategies (strategy_id);

CREATE INDEX idx_strategies_fixed_order
    ON strategies (strategy_name, strategy_id, row_id);

CREATE TABLE portfolio_strategies (
    row_id        INTEGER PRIMARY KEY,
    portfolio_id  ANY,
    strategy_id   ANY
) STRICT;

CREATE INDEX idx_portfolio_strategies_portfolio
    ON portfolio_strategies (portfolio_id, strategy_id, row_id);

CREATE INDEX idx_portfolio_strategies_strategy
    ON portfolio_strategies (strategy_id, portfolio_id, row_id);

CREATE TABLE positions (
    row_id                INTEGER PRIMARY KEY,
    position_id           ANY,
    portfolio_id          ANY,
    instrument_id         ANY,
    as_of_date            ANY,
    quantity              ANY,
    market_price_amount   ANY,
    market_price_currency ANY,
    market_value_amount   ANY,
    market_value_currency ANY
) STRICT;

CREATE INDEX idx_positions_position_id
    ON positions (position_id);

CREATE INDEX idx_positions_query
    ON positions (as_of_date, portfolio_id, instrument_id, row_id);

CREATE INDEX idx_positions_instrument
    ON positions (instrument_id, as_of_date, portfolio_id, row_id);

CREATE TABLE transactions (
    row_id              INTEGER PRIMARY KEY,
    transaction_id      ANY,
    portfolio_id        ANY,
    instrument_id       ANY,
    transaction_type    ANY,
    trade_date          ANY,
    booking_date        ANY,
    quantity            ANY,
    net_amount          ANY,
    net_amount_currency ANY
) STRICT;

CREATE INDEX idx_transactions_transaction_id
    ON transactions (transaction_id);

CREATE INDEX idx_transactions_fixed_order
    ON transactions (booking_date DESC, transaction_id, row_id);

CREATE INDEX idx_transactions_portfolio
    ON transactions (portfolio_id, booking_date DESC, transaction_id, row_id);

CREATE INDEX idx_transactions_type
    ON transactions (transaction_type, booking_date DESC, transaction_id, row_id);

CREATE TABLE performance_records (
    row_id                       INTEGER PRIMARY KEY,
    performance_id               ANY,
    portfolio_id                 ANY,
    granularity                  ANY,
    period_start                 ANY,
    period_end                   ANY,
    portfolio_return_percentage  ANY,
    benchmark_return_percentage  ANY
) STRICT;

CREATE INDEX idx_performance_performance_id
    ON performance_records (performance_id);

CREATE INDEX idx_performance_query
    ON performance_records (
        period_start,
        portfolio_id,
        granularity,
        performance_id,
        row_id
    );

CREATE TABLE allocation_orders (
    row_id                  INTEGER PRIMARY KEY,
    allocation_order_id     ANY,
    client_order_reference  ANY,
    portfolio_id            ANY,
    instrument_id           ANY,
    side                    ANY,
    quantity                ANY,
    status                  ANY,
    created_at              ANY,
    updated_at              ANY
) STRICT;

CREATE INDEX idx_allocation_orders_order_id
    ON allocation_orders (allocation_order_id);

CREATE INDEX idx_allocation_orders_client_reference
    ON allocation_orders (portfolio_id, client_order_reference, row_id);

CREATE INDEX idx_allocation_orders_status
    ON allocation_orders (status, allocation_order_id, row_id);

CREATE TABLE allocation_order_allocations (
    row_id               INTEGER PRIMARY KEY,
    allocation_order_id  ANY,
    sequence_number      ANY,
    strategy_id          ANY,
    percentage           ANY
) STRICT;

CREATE INDEX idx_order_allocations_order
    ON allocation_order_allocations (
        allocation_order_id,
        sequence_number,
        row_id
    );

CREATE INDEX idx_order_allocations_strategy
    ON allocation_order_allocations (strategy_id, allocation_order_id, row_id);

PRAGMA user_version = 1;

COMMIT;
