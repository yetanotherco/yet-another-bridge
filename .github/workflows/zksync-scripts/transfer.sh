#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making transfer to Destination account${COLOR_RESET}\n"

BALANCE_MM_L1_BEFORE_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
echo "\nInitial MM Balance: $BALANCE_MM_L1_BEFORE_TRANSFER"

BALANCE_USER_L1_BEFORE_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $USER_ETHEREUM_PUBLIC_ADDRESS)
echo "\nInitial User Balance: $BALANCE_USER_L1_BEFORE_TRANSFER"

echo "Transferring $BRIDGE_AMOUNT_ETH ETH to $USER_ETHEREUM_PUBLIC_ADDRESS"
cast send --rpc-url $ETHEREUM_RPC --private-key $MM_ETHEREUM_PRIVATE_KEY --gas-price 2000000000 \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "transfer(uint256, address, uint128)" \
  "0" $USER_ETHEREUM_PUBLIC_ADDRESS $ZKSYNC_CHAIN_ID \
  --value $BRIDGE_AMOUNT_WEI >> /dev/null

BALANCE_MM_L1_AFTER_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
echo "\nFinal MM Balance: $BALANCE_MM_L1_AFTER_TRANSFER"

BALANCE_USER_L1_AFTER_TRANSFER_WEI=$(cast balance --rpc-url $ETHEREUM_RPC $USER_ETHEREUM_PUBLIC_ADDRESS)
BALANCE_USER_L1_AFTER_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC --ether $USER_ETHEREUM_PUBLIC_ADDRESS)
echo "\nFinal User Balance: $BALANCE_USER_L1_AFTER_TRANSFER"
