#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

if [ -f ./contracts/solidity/.env ]; then
    echo "Sourcing .env file..."
    source ./contracts/solidity/.env
else
    echo "Error: .env file not found!"
    exit 1
fi

echo -e "${GREEN}\n=> [ETH] Deploy Escrow${COLOR_RESET}"
forge script ./script/Deploy.s.sol --fork-url $GOERLI_RPC_URL --broadcast --verify -vvvv