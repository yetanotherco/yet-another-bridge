#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

#fee=24044002524012
FEE=25000000000000
APPROVE_AMOUNT=$((${AMOUNT}+${FEE}))

echo -e "${GREEN}\n=> [SN] Making SetOrder on Escrow${COLOR_RESET}"

starkli invoke \
  $NATIVE_TOKEN_ETH_STARKNET approve $ESCROW_CONTRACT_ADDRESS u256:$APPROVE_AMOUNT \
  / $ESCROW_CONTRACT_ADDRESS set_order 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  u256:$AMOUNT u256:$FEE --private-key $STARKNET_PRIVATE_KEY --account $STARKNET_ACCOUNT
  