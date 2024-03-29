CREATE TABLE IF NOT EXISTS orders
(
    order_id          INT            NOT NULL,
    origin_network    VARCHAR(32)    NOT NULL,

    recipient_address VARCHAR(42)    NOT NULL, -- 0x + 40 bytes
    amount            NUMERIC(78, 0) NOT NULL, -- uint 256
    fee               NUMERIC(78, 0) NOT NULL, -- uint 256

    status            VARCHAR(32)    NOT NULL DEFAULT 'PENDING',
    failed            BOOLEAN        NOT NULL DEFAULT FALSE,

    set_order_tx_hash BYTEA          NOT NULL, -- 66 chars
    transfer_tx_hash  BYTEA          NULL,     -- 32 bytes
    claim_tx_hash     BYTEA          NULL,     -- 32 bytes

    herodotus_task_id VARCHAR(64)    NULL,
    herodotus_block   BIGINT         NULL,     -- uint 64
    herodotus_slot    BYTEA          NULL,     -- 32 bytes

    created_at        TIMESTAMP      NOT NULL DEFAULT clock_timestamp(),
    transferred_at    TIMESTAMP      NULL,
    completed_at      TIMESTAMP      NULL,

    PRIMARY KEY (order_id, origin_network)
);

CREATE TABLE IF NOT EXISTS block
(
    id           SERIAL PRIMARY KEY,
    network      VARCHAR(32) NOT NULL,
    latest_block BIGINT    NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT clock_timestamp()
);

INSERT INTO block (latest_block) VALUES (0) ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS error
(
    id         SERIAL PRIMARY KEY,
    order_id   INT       NOT NULL,
    origin_network VARCHAR(32) NOT NULL,
    message    TEXT      NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT clock_timestamp(),

    FOREIGN KEY (order_id, origin_network) REFERENCES orders (order_id, origin_network) ON DELETE CASCADE
);
