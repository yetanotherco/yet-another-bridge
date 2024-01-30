#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd contracts/solidity

echo -e "${GREEN}\n=> [ETH] Deploying ERC1967Proxy & YABTransfer ${COLOR_RESET}"

RESULT_LOG=$(forge script ./script/Deploy.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
YAB_TRANSFER_PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')
YAB_TRANSFER_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '1: address ([^\n]+)' | awk '{print $NF}')

echo -e "${GREEN}\n=> [ETH] Deployed Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}"
echo -e "${GREEN}\n=> [ETH] Deployed YABTransfer address: $YAB_TRANSFER_ADDRESS ${COLOR_RESET}"

echo "If you now wish to deploy SN Escrow, you will need to run the following command:"
echo "export YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS"
echo "make starknet-deploy"

cd ../.. #to reset working directory
