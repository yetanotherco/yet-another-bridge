#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

assert() {
  # Usage: assert <condition> <placeholder_text> <expected_value> <obtained_value>
  if eval "$1"; then
    printf "${GREEN}✓ $2 passed.${RESET}\n"
  else
    printf "${RED}⨯ $2 assertion failed: Expected value: $3, Obtained value: $4.${RESET}\n"
    exit 1
  fi
}

echo ""

DESTINATION_FINAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC $DESTINATION_ADDRESS)
EXPECTED_DESTINATION_FINAL_BALANCE=10001000000000000000000
assert "[[ $DESTINATION_FINAL_BALANCE -eq $EXPECTED_DESTINATION_FINAL_BALANCE ]]" "Destination balance" "$EXPECTED_DESTINATION_FINAL_BALANCE" "$DESTINATION_FINAL_BALANCE"

ESCROW_FINAL_BALANCE=$(starkli balance --raw $ESCROW_CONTRACT_ADDRESS)
EXPECTED_ESCROW_FINAL_BALANCE=0
assert "[[ $ESCROW_FINAL_BALANCE -eq $EXPECTED_ESCROW_FINAL_BALANCE ]]" "Escrow balance" "$EXPECTED_ESCROW_FINAL_BALANCE" "$ESCROW_FINAL_BALANCE"

MM_FINAL_BALANCE=$(starkli balance --raw $MM_STARKNET_WALLET)
EXPECTED_MM_FINAL_BALANCE=1001000025000000000000
assert "[[ $MM_FINAL_BALANCE -eq $EXPECTED_MM_FINAL_BALANCE ]]" "MM balance" "$EXPECTED_MM_FINAL_BALANCE" "$MM_FINAL_BALANCE"
