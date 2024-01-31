#!/bin/bash

# ANSI format
GREEN='\e[32m'
CYAN='\033[36m'
PINK='\033[1;35m'
COLOR_RESET='\033[0m'

# Starkli implicitly utilizes these environment variables, so every time we use Starkli,
# we avoid adding flags such as --account, --keystore, and --rpc.
export STARKNET_ACCOUNT=$STARKNET_ACCOUNT
export STARKNET_KEYSTORE=$STARKNET_KEYSTORE
# export STARKNET_RPC=$STARKNET_RPC #todo: this must remain commented until we find a reliable and compatible rpc

if [ -z "$ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

cd contracts/cairo

printf "${GREEN}\n=> [SN] Declare Escrow${COLOR_RESET}\n"
NEW_ESCROW_CLASS_HASH=$(starkli declare --watch target/dev/yab_Escrow.contract_class.json)

if [ -z "$NEW_ESCROW_CLASS_HASH" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "Failed to generate New Escrow Class Hash. Aborting execution.\n"
    exit 1
fi

printf "${CYAN}[SN] Escrow address: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"
printf "${CYAN}[SN] New Escrow ClassHash: $NEW_ESCROW_CLASS_HASH${COLOR_RESET}\n"

printf "${GREEN}\n=> [SN] Upgrade Escrow${COLOR_RESET}\n"
starkli invoke --watch $ESCROW_CONTRACT_ADDRESS upgrade $NEW_ESCROW_CLASS_HASH

cd ../..
