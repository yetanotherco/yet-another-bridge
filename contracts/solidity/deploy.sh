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

echo -e "${GREEN}\n=> [ETH] Deploy ERC1967Proxy & YABTransfer ${COLOR_RESET}"
RESULT_LOG=$(forge script ./script/Deploy.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)

# Setting result address into .env file
YAB_TRANSFER_PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '0: address \K[^\n]+' | awk '{print $0}')
echo -e "${GREEN}\n=> [ETH] Deployed Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}"
sed -i "s/^YAB_TRANSFER_PROXY_ADDRESS=.*/YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS/" ".env" || echo "YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS" >> ".env"
