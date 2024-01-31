#!/bin/bash

# ANSI format
GREEN='\e[32m'
RESET='\e[0m'

echo -e "${GREEN}\n=> [SN] Making withdraw${COLOR_RESET}" # 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 -> 642829559307850963015472508762062935916233390536

ESCROW_INITIAL_BALANCE=$(starkli balance $ESCROW_CONTRACT_ADDRESS)
MM_INITIAL_BALANCE=$(starkli balance $MM_SN_WALLET_ADDR)
echo "Initial Escrow balance: $ESCROW_INITIAL_BALANCE"
echo "Initial MM balance: $MM_INITIAL_BALANCE"

echo "Withdrawing $amount"
cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY \
  $YAB_TRANSFER_PROXY_ADDRESS "withdraw(uint256, uint256, uint256)" \
  "0" "642829559307850963015472508762062935916233390536" "$AMOUNT" \
  --value $AMOUNT >> /dev/null

starkli call $ESCROW_CONTRACT_ADDRESS get_order_used u256:0

ESCROW_FINAL_BALANCE=$(starkli balance $ESCROW_CONTRACT_ADDRESS)
MM_FINAL_BALANCE=$(starkli balance $MM_SN_WALLET_ADDR)
echo "Final Escrow balance: $ESCROW_FINAL_BALANCE"
echo "Final MM balance: $MM_FINAL_BALANCE"
