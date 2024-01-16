#!/bin/bash

approve=124000000000000
amount=124000000000000

starkli invoke eth approve 0x07b436a3148e98d4e9fb5d535c45526d06495d24421a24becfc7361884371613 u256:$approve / 0x07b436a3148e98d4e9fb5d535c45526d06495d24421a24becfc7361884371613 set_order 0x769383FbA3f8c007D19C8FE57cF4422A93522b84 u256:$amount u256:0 --keystore ~/.starkli-wallets/keystore.json --account ~/.starkli-wallets/account.json
