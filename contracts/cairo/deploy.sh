#!/bin/bash

# ANSI format
GREEN='\e[32m'
PURPLE='\033[1;34m'
PINK='\033[1;35m'
COLOR_RESET='\033[0m'

HERODOTUS_FACTS_REGISTRY=0x01b2111317EB693c3EE46633edd45A4876db14A3a53ACDBf4E5166976d8e869d
MM_ETHEREUM_WALLET=0xE8504996d2e25735FA88B3A0a03B4ceD2d3086CC
NATIVE_TOKEN_ETH_STARKNET=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7

cd "$(dirname "$0")"

load_env() {
    unamestr=$(uname)
    if [ "$unamestr" = 'Linux' ]; then
      export $(grep -v '^#' ../../mm-bot/.env | xargs -d '\n')
    elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
      export $(grep -v '^#' ../../mm-bot/.env | xargs -0)
    fi
}
load_env

echo -e "${GREEN}\n=> [SN] Declare Escrow${COLOR_RESET}"
echo "On network:" $1
ESCROW_CLASS_HASH=$(starkli declare --network $1 --watch target/dev/yab_Escrow.contract_class.json)

echo -e "- ${PURPLE}[SN] Escrow ClassHash: $ESCROW_CLASS_HASH${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Herodotus Facts Registry: $HERODOTUS_FACTS_REGISTRY${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Market Maker: $SN_WALLET_ADDR${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Ethereum ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Ethereum ContractAddress: $ETH_CONTRACT_ADDR${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Market Maker: $MM_ETHEREUM_WALLET${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Deploy Escrow${COLOR_RESET}"
ESCROW_CONTRACT_ADDRESS=$(starkli deploy --network $1 --watch $ESCROW_CLASS_HASH \
    $HERODOTUS_FACTS_REGISTRY \
    $ETH_CONTRACT_ADDR \
    $MM_ETHEREUM_WALLET \
    $SN_WALLET_ADDR \
    $NATIVE_TOKEN_ETH_STARKNET)
echo -e "- ${PURPLE}[SN] Escrow ContractAddress: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}"
