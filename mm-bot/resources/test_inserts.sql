INSERT INTO orders (order_id, origin_network, from_address, recipient_address, amount, fee, set_order_tx_hash)
VALUES
(1, 'NetworkA', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x1234567890123456789012345678901234567890', 1000, 10, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(2, 'NetworkB', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x2234567890123456789012345678901234567890', 2000, 20, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(3, 'NetworkA', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x3234567890123456789012345678901234567890', 3000, 30, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(4, 'NetworkC', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x4234567890123456789012345678901234567890', 4000, 40, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'),
(5, 'NetworkB', '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef', '0x5234567890123456789012345678901234567890', 5000, 50, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef');

INSERT INTO block (network, latest_block)
VALUES
('NetworkA', 1000),
('NetworkB', 2000),
('NetworkC', 3000),
('NetworkA', 4000),
('NetworkB', 5000);

INSERT INTO error (order_id, origin_network, message)
VALUES
(1, 'NetworkA', 'Error message 1 for order 1 on NetworkA'),
(2, 'NetworkB', 'Error message 2 for order 2 on NetworkB'),
(3, 'NetworkA', 'Error message 3 for order 3 on NetworkA'),
(4, 'NetworkC', 'Error message 4 for order 4 on NetworkC'),
(5, 'NetworkB', 'Error message 5 for order 5 on NetworkB');
