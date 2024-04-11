#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making transfer to Destination account${COLOR_RESET}\n"


BALANCE_MM_L1_BEFORE_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_WALLET_ADDRESS)
BALANCE_USER_L1_BEFORE_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC --ether $USER_ETHEREUM_PUBLIC_ADDRESS)
echo "Initial MM balance: $BALANCE_MM_L1_BEFORE_TRANSFER"
echo "Initial Destination balance: $BALANCE_USER_L1_BEFORE_TRANSFER"


echo "Transferring $BRIDGE_AMOUNT_WEI WEI to $USER_ETHEREUM_PUBLIC_ADDRESS"

cast send --rpc-url $ETHEREUM_RPC --private-key $MM_ETHEREUM_PRIVATE_KEY --gas-price 2000000000 \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "transfer(uint256, address, uint128)" \
  "0" $USER_ETHEREUM_PUBLIC_ADDRESS $ZKSYNC_CHAIN_ID \
  --value $BRIDGE_AMOUNT_WEI >> /dev/null


BALANCE_MM_L1_AFTER_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_WALLET_ADDRESS)
BALANCE_USER_L1_AFTER_TRANSFER=$(cast balance --rpc-url $ETHEREUM_RPC --ether $USER_ETHEREUM_PUBLIC_ADDRESS)
echo "Final MM balance: $BALANCE_MM_L1_AFTER_TRANSFER"
echo "Final Destination balance: $BALANCE_USER_L1_AFTER_TRANSFER"
