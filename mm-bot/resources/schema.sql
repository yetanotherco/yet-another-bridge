CREATE TABLE IF NOT EXISTS orders
(
    order_id             INT PRIMARY KEY,
    recipient_address    VARCHAR(42)    NOT NULL, -- 0x + 40 bytes
    amount               NUMERIC(78, 0) NOT NULL, -- uint 256
    status               VARCHAR(32)    NOT NULL DEFAULT 'PENDING',
    tx_hash              BYTEA          NULL,     -- 32 bytes
    herodotus_task_id    VARCHAR(64)    NULL,
    herodotus_block      BIGINT         NULL,     -- uint 64
    herodotus_slot       BYTEA          NULL,     -- 32 bytes
    eth_withdraw_tx_hash BYTEA          NULL,     -- 32 bytes
    created_at           TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS block
(
    id           SERIAL PRIMARY KEY,
    latest_block BIGINT    NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
