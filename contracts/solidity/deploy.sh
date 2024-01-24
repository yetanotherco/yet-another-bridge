#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

#if [ -f .env ]; then
#    echo "Sourcing solidity/.env file..."
#    source .env
#else
#    echo "Error: solidity/.env file not found!"
#    exit 1
#fi

echo -e "${GREEN}\n=> [ETH] Deploy Escrow${COLOR_RESET}"
forge script ./script/Deploy.s.sol --fork-url $ETH_RPC_URL --broadcast ${SKIP_VERIFY:---verify} -vvvv
