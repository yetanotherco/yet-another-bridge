#!/bin/bash

if [ -z "$STARKNET_ACCOUNT" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_ACCOUNT Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$STARKNET_KEYSTORE" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_KEYSTORE Variable is empty. Aborting execution.\n"
    exit 1
fi

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

if [[ $1 == 'pause' ]]; then
    starkli invoke $ESCROW_CONTRACT_ADDRESS pause
elif [[ "$1" == 'unpause' ]]; then
    starkli invoke $ESCROW_CONTRACT_ADDRESS unpause
else
    echo "Error, parameter must be 'pause' or 'unpause'"
fi
