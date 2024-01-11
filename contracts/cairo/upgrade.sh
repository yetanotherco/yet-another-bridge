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
export STARKNET_RPC=$STARKNET_RPC

if [ -z "$SN_PROXY_ESCROW_ADDRESS" ]; then
    echo "Error: SN_PROXY_ESCROW_ADDRESS environment variable is not set. Please set it before running this script."
    exit 1
fi

cd "$(dirname "$0")"

echo -e "${GREEN}\n=> [SN] Declare Escrow${COLOR_RESET}"
NEW_ESCROW_CLASS_HASH=$(starkli declare --watch target/dev/yab_Escrow.contract_class.json)
echo -e "- ${PURPLE}[SN] Escrow Proxy Address: $SN_PROXY_ESCROW_ADDRESS${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] New Escrow ClassHash Impl: $NEW_ESCROW_CLASS_HASH${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Upgrade Proxy${COLOR_RESET}"
starkli invoke --watch $SN_PROXY_ESCROW_ADDRESS upgrade $NEW_ESCROW_CLASS_HASH
