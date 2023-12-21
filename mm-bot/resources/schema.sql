CREATE TABLE IF NOT EXISTS orders
(
    order_id          INT PRIMARY KEY,
    recipient_address VARCHAR(42) NOT NULL,
    amount            NUMERIC(78, 0)         NOT NULL,
    status            VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    herodotus_task_id VARCHAR(64) NULL,
    created_at        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

