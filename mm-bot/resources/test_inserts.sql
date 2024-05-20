-- ZKSYNC mainnet -> network = 324
-- STARKNET mainnet -> network = 0x534e5f4d41494e


INSERT INTO orders (order_id, origin_network, from_address, recipient_address, amount, fee, status, failed, set_order_tx_hash)
VALUES
(1, '324', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x1234567890123456789012345678901234567890', 1000, 10, 'PENDING', FALSE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(2, '0x534e5f4d41494e', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x2234567890123456789012345678901234567890', 2000, 20, 'COMPLETED', FALSE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(3, '324', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x3234567890123456789012345678901234567890', 3000, 30, 'DROPPED', TRUE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(4, '0x534e5f4d41494e', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x4234567890123456789012345678901234567890', 4000, 40, 'PENDING', FALSE, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef');

INSERT INTO block (network, latest_block)
VALUES
('324', 1000),
('0x534e5f4d41494e', 2000),
('324', 3000),
('0x534e5f4d41494e', 4000);

INSERT INTO error (order_id, origin_network, message)
VALUES
(1, '324', 'Error message 1 for order 1 on ZKSYNC mainnet'),
(2, '0x534e5f4d41494e', 'Error message 2 for order 2 on STARKNET mainnet'),
(3, '324', 'Error message 3 for order 3 on ZKSYNC mainnet'),
(4, '0x534e5f4d41494e', 'Error message 4 for order 4 on STARKNET mainnet');
