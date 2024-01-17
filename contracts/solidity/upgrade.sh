#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

if [ -f .env ]; then
    echo "Sourcing solidity/.env file..."
    source .env
else
    echo "Error: solidity/.env file not found!"
    exit 1
fi

echo -e "${GREEN}\n=> [ETH] Upgrading YABTransfer ${COLOR_RESET}"

RESULT_LOG=$(forge script ./script/Upgrade.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '0: address \K[^\n]+' | awk '{print $0}')
YAB_TRANSFER_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '1: address \K[^\n]+' | awk '{print $0}')

echo -e "${GREEN}\n=> [ETH] Unchanged YABTransfer Proxy address: $PROXY_ADDRESS ${COLOR_RESET}"
echo -e "${GREEN}\n=> [ETH] Newly Deployed YABTransfer contract address: $YAB_TRANSFER_ADDRESS ${COLOR_RESET}"
