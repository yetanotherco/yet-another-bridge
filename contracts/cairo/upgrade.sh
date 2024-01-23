#!/bin/bash

# ANSI format
GREEN='\e[32m'
PURPLE='\033[1;34m'
PINK='\033[1;35m'
COLOR_RESET='\033[0m'

if [ -f ./contracts/cairo/.env ]; then
    echo "Sourcing .env file..."
    source ./contracts/cairo/.env
else
    echo "Error: .env file not found!"
    exit 1
fi

# Starkli implicitly utilizes these environment variables, so every time we use Starkli,
# we avoid adding flags such as --account, --keystore, and --rpc.
export STARKNET_ACCOUNT=$STARKNET_ACCOUNT
export STARKNET_KEYSTORE=$STARKNET_KEYSTORE
# export STARKNET_RPC=$STARKNET_RPC #this must remain commented until we find a reliable and compatible rpc

if [ -z "$ESCROW_CONTRACT_ADDRESS" ]; then
    echo "Error: ESCROW_CONTRACT_ADDRESS environment variable is not set. Please set it before running this script."
    exit 1
fi

cd "$(dirname "$0")"

echo -e "${GREEN}\n=> [SN] Declare Escrow${COLOR_RESET}"
NEW_ESCROW_CLASS_HASH=$(starkli declare --watch target/dev/yab_Escrow.contract_class.json)
echo -e "- ${PURPLE}[SN] Escrow address: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] New Escrow ClassHash: $NEW_ESCROW_CLASS_HASH${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Upgrade Escrow${COLOR_RESET}"
starkli invoke --watch $ESCROW_CONTRACT_ADDRESS upgrade $NEW_ESCROW_CLASS_HASH