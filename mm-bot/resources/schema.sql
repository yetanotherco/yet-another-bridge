CREATE TABLE IF NOT EXISTS orders
(
    order_id             INT PRIMARY KEY,
    starknet_tx_hash     VARCHAR(66)    NOT NULL, -- 66 chars
    recipient_address    VARCHAR(42)    NOT NULL, -- 0x + 40 bytes
    amount               NUMERIC(78, 0) NOT NULL, -- uint 256
    status               VARCHAR(32)    NOT NULL DEFAULT 'PENDING',
    failed               BOOLEAN        NOT NULL DEFAULT FALSE,
    tx_hash              BYTEA          NULL,     -- 32 bytes
    transferred_at       TIMESTAMP      NULL,
    herodotus_task_id    VARCHAR(64)    NULL,
    herodotus_block      BIGINT         NULL,     -- uint 64
    herodotus_slot       BYTEA          NULL,     -- 32 bytes
    eth_withdraw_tx_hash BYTEA          NULL,     -- 32 bytes
    completed_at         TIMESTAMP      NULL,
    created_at           TIMESTAMP      NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS block
(
    id           SERIAL PRIMARY KEY,
    latest_block BIGINT    NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT clock_timestamp()
);

INSERT INTO block (latest_block) VALUES (0) ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS error
(
    id         SERIAL PRIMARY KEY,
    order_id   INT       NOT NULL,
    message    TEXT      NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT clock_timestamp(),

    FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE
);
