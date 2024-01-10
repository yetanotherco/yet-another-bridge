#!/bin/bash
if [ -f ./contracts/solidity/.env ]; then
    echo "Sourcing solidity/.env file..."
    source ./contracts/solidity/.env
else
    echo "Error: solidity/.env file not found!"
    exit 1
fi
if [ -f ./contracts/cairo/.env ]; then
    echo "Sourcing cairo/.env file..."
    source ./contracts/cairo/.env
else
    echo "Error: cairo/.env file not found!"
    exit 1
fi

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

echo -e "${GREEN}\n=> [ETH] Setting Starknet Withdraw Selector on ETH Smart Contract${COLOR_RESET}"
echo "Smart contract being modified:" $ETH_CONTRACT_ADDR
echo "New Withdraw Selector:" $1
cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $ETH_CONTRACT_ADDR "setEscrowWithdrawSelector(uint256)" $1
# example param: 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77