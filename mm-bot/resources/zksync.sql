-- This a script to migrate the original implementation to the implementation with origin_network field

ALTER TABLE orders ADD COLUMN origin_network VARCHAR(32) NOT NULL DEFAULT 'STARKNET';

-- Modify the orders primary key to include the new column
ALTER TABLE orders DROP CONSTRAINT orders_pkey CASCADE; -- Cascade is needed to drop the foreign key constraint
ALTER TABLE orders ADD PRIMARY KEY (order_id, origin_network);

-- Set new error foreign key
ALTER TABLE error ADD COLUMN origin_network VARCHAR(32) NOT NULL DEFAULT 'STARKNET';
ALTER TABLE error ADD CONSTRAINT errors_order_id_fkey FOREIGN KEY (order_id, origin_network) REFERENCES orders(order_id, origin_network);

-- Add set_order_tx_hash column to orders table
ALTER TABLE orders ADD COLUMN set_order_tx_hash BYTEA;

ALTER TABLE orders alter starknet_tx_hash drop not null;

-- Rename tx_hash to transfer_tx_hash
ALTER TABLE orders RENAME COLUMN tx_hash TO transfer_tx_hash;

-- Rename eth_claim_tx_hash to claim_tx_hash
ALTER TABLE orders RENAME COLUMN eth_claim_tx_hash TO claim_tx_hash;

-- Add network column to block table with default value 'STARKNET'
ALTER TABLE block ADD COLUMN network VARCHAR(32) NOT NULL DEFAULT 'STARKNET';
