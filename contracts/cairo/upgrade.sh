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

if [ -z "$SN_PROXY_ESCROW_ADDRESS" ]; then
    echo "Error: SN_PROXY_ESCROW_ADDRESS environment variable is not set. Please set it before running this script."
    exit 1
fi

cd "$(dirname "$0")"

echo -e "${GREEN}\n=> [SN] Declare Escrow${COLOR_RESET}"
NEW_ESCROW_CLASS_HASH=$(starkli declare --watch --rpc $STARKNET_RPC target/dev/yab_Escrow.contract_class.json)
echo -e "- ${PURPLE}[SN] New Escrow ClassHash: $NEW_ESCROW_CLASS_HASH${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Upgrade Proxy${COLOR_RESET}"
$(starkli invoke --rpc $STARKNET_RPC $SN_PROXY_ESCROW_ADDRESS upgrade $NEW_ESCROW_CLASS_HASH)
