#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making transfer to Destination account${COLOR_RESET}\n"

echo "\nMM L1 funds before transfer:"
BALANCE_MM_L1_BEFORE_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
echo $BALANCE_MM_L1_BEFORE_TRANSFER

echo "\nUser L1 funds before transfer:"
BALANCE_USER_L1_BEFORE_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $USER_ETHEREUM_PUBLIC_ADDRESS)
echo $BALANCE_USER_L1_BEFORE_TRANSFER

echo "Transferring $BRIDGE_AMOUNT_WEI WEI to $USER_ETHEREUM_PUBLIC_ADDRESS"
cast send --rpc-url $ETHEREUM_RPC --private-key $MM_ETHEREUM_PRIVATE_KEY --gas-price 2000000000 \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "transfer(uint256, address, uint128)" \
  "0" $USER_ETHEREUM_PUBLIC_ADDRESS $ZKSYNC_CHAIN_ID \
  --value $BRIDGE_AMOUNT_WEI >> /dev/null

echo "\nMM L1 funds after transfer:"
BALANCE_MM_L1_AFTER_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
echo $BALANCE_MM_L1_AFTER_TRANSFER

echo "\nUser L1 funds after transfer:"
BALANCE_USER_L1_AFTER_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC $USER_ETHEREUM_PUBLIC_ADDRESS)
echo $BALANCE_MM_L1_AFTER_TRANSFER
