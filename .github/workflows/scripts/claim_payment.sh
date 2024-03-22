#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

DESTINATION_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

echo -e "${GREEN}\n=> [SN] Making ClaimPayment${COLOR_RESET}" # 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 -> 642829559307850963015472508762062935916233390536

ESCROW_INITIAL_BALANCE=$(starkli balance $ESCROW_CONTRACT_ADDRESS)
MM_INITIAL_BALANCE=$(starkli balance $MM_STARKNET_WALLET_ADDRESS)
echo "Initial Escrow balance: $ESCROW_INITIAL_BALANCE"
echo "Initial MM balance: $MM_INITIAL_BALANCE"

echo "Withdrawing $AMOUNT"
cast send --rpc-url $ETHEREUM_RPC --private-key $ETHEREUM_PRIVATE_KEY \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "claimPayment(uint256, address, uint256)" \
  "0" $DESTINATION_ADDRESS "$AMOUNT" \
  --value $AMOUNT >> /dev/null

sleep 15

starkli call $ESCROW_CONTRACT_ADDRESS get_order_pending u256:0

ESCROW_FINAL_BALANCE=$(starkli balance $ESCROW_CONTRACT_ADDRESS)
MM_FINAL_BALANCE=$(starkli balance $MM_STARKNET_WALLET_ADDRESS)
echo "Final Escrow balance: $ESCROW_FINAL_BALANCE"
echo "Final MM balance: $MM_FINAL_BALANCE"
