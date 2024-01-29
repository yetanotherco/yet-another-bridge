#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

# cd "$(dirname "$0")"
cd contracts/solidity

if [ -z "$YAB_TRANSFER_PROXY_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "YAB_TRANSFER_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$ETH_PRIVATE_KEY" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "ETH_PRIVATE_KEY Variable is empty. Aborting execution.\n"
    exit 1
fi

echo "${GREEN}\n=> [ETH] Upgrading YABTransfer ${COLOR_RESET}"

RESULT_LOG=$(forge script ./script/Upgrade.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '0: address \K[^\n]+' | awk '{print $0}')
YAB_TRANSFER_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '1: address \K[^\n]+' | awk '{print $0}')

if [ -z "$YAB_TRANSFER_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "YAB_TRANSFER_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

echo "${GREEN}\n=> [ETH] Unchanged YABTransfer Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}"
echo "${GREEN}\n=> [ETH] Newly Deployed YABTransfer contract address: $YAB_TRANSFER_ADDRESS ${COLOR_RESET}"

cd ../..