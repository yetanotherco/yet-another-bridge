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

cd "$(dirname "$0")"

echo -e "${GREEN}\n=> [SN] Declare Escrow${COLOR_RESET}"
ESCROW_CLASS_HASH=$(starkli declare --watch target/dev/yab_Escrow.contract_class.json)

echo -e "- ${PURPLE}[SN] Escrow ClassHash: $ESCROW_CLASS_HASH${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Herodotus Facts Registry: $HERODOTUS_FACTS_REGISTRY${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Market Maker: $MM_SN_WALLET_ADDRESS${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Ethereum ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Ethereum ContractAddress: $ETH_CONTRACT_ADDR${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Market Maker: $MM_ETHEREUM_WALLET${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Deploy Escrow${COLOR_RESET}"
ESCROW_CONTRACT_ADDRESS=$(starkli deploy --watch $ESCROW_CLASS_HASH \
    $SN_PROXY_OWNER \
    $HERODOTUS_FACTS_REGISTRY \
    $ETH_CONTRACT_ADDR \
    $MM_ETHEREUM_WALLET \
    $MM_SN_WALLET_ADDRESS \
    $NATIVE_TOKEN_ETH_STARKNET)
echo -e "- ${PURPLE}[SN] Escrow ContractAddress: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}"
