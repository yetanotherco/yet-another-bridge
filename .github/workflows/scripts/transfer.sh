#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

DESTINATION_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

echo -e "${GREEN}\n=> [SN] Making transfer to Destination account${COLOR_RESET}" # 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 -> 642829559307850963015472508762062935916233390536

MM_INITIAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_WALLET_ADDRESS)
DESTINATION_INITIAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $DESTINATION_ADDRESS)
echo "Initial MM balance: $MM_INITIAL_BALANCE"
echo "Initial Destination balance: $DESTINATION_INITIAL_BALANCE"

echo "Transferring $AMOUNT to $DESTINATION_ADDRESS"
cast send --rpc-url $ETHEREUM_RPC --private-key $ETHEREUM_PRIVATE_KEY \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "transfer(uint256, address, uint128)" \
  "0" $DESTINATION_ADDRESS $STARKNET_CHAIN_ID \
  --value $AMOUNT >> /dev/null

MM_FINAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_WALLET_ADDRESS)
DESTINATION_FINAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $DESTINATION_ADDRESS)
echo "Final MM balance: $MM_FINAL_BALANCE"
echo "Final Destination balance: $DESTINATION_FINAL_BALANCE"
