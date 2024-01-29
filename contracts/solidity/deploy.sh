#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd contracts/solidity

echo "${GREEN}\n=> [ETH] Deploying ERC1967Proxy & YABTransfer ${COLOR_RESET}"

RESULT_LOG=$(forge script ./script/Deploy.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
YAB_TRANSFER_PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')
YAB_TRANSFER_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '1: address ([^\n]+)' | awk '{print $NF}')

echo "${GREEN}\n=> [ETH] Deployed Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}"
echo "${GREEN}\n=> [ETH] Deployed YABTransfer address: $YAB_TRANSFER_ADDRESS ${COLOR_RESET}"

cd ../.. #to reset working directory
