#!/bin/bash

# ANSI format
GREEN='\e[32m'
RED='\033[0;31m'
RESET='\e[0m'

# Define the assert function
assert() {
  # Usage: assert <condition> <placeholder_text> <expected_value> <obtained_value>
  if "$1"; then
    echo "${GREEN}$2 passed.${RESET}"
  else
    echo "${RED}$2 assertion failed: Expected value: $3, Obtained value: $4${RESET}"
    exit 1
  fi
}

DESTINATION_FINAL_BALANCE=$(cast balance --rpc-url $ETH_RPC_URL $DESTINATION_ADDRESS)
EXPECTED_DESTINATION_FINAL_BALANCE=10001000000000000000000
assert "[[ $DESTINATION_FINAL_BALANCE -eq $expected_DESTINATION_FINAL_BALANCE ]]" "Destination balance" "10001000000000000000000" "$DESTINATION_FINAL_BALANCE"

