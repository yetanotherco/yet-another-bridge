#!/bin/bash
. contracts/general/colors.sh #for ANSI colors

cd contracts/solidity

printf "${GREEN}\n=> [ETH] Deploying ERC1967Proxy & YABTransfer ${COLOR_RESET}\n"

RESULT_LOG=$(forge script ./script/Deploy.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
YAB_TRANSFER_PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')
YAB_TRANSFER_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '1: address ([^\n]+)' | awk '{print $NF}')

printf "${GREEN}\n=> [ETH] Deployed Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}\n"
printf "${GREEN}\n=> [ETH] Deployed YABTransfer address: $YAB_TRANSFER_ADDRESS ${COLOR_RESET}\n"

echo "\nIf you now wish to deploy SN Escrow, you will need to run the following commands:"
echo "export YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS"
echo "make starknet-deploy"

cd ../.. #to reset working directory
