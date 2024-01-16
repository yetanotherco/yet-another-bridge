#!/bin/bash

# ANSI format
GREEN='\e[32m'
PURPLE='\033[1;34m'
PINK='\033[1;35m'
ORANGE='\033[1;33m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

if [ -f .env ]; then
    echo "Sourcing cairo/.env file..."
    source .env
else
    echo "Error: cairo/.env file not found!"
    exit 1
fi

if ! grep -q "^SN_ESCROW_OWNER=" ".env"; then
  echo "" #\n
  echo -e "${ORANGE}WARNING:${COLOR_RESET} no SN_ESCROW_OWNER defined in .env, declaring deployer as the owner of the contract"
  SN_ESCROW_OWNER=$(cat "$STARKNET_ACCOUNT" | grep '"address"' | sed -E 's/.*"address": "([^"]+)".*/\1/')
fi


echo -e "${GREEN}\n=> [SN] Declaring Escrow${COLOR_RESET}"
ESCROW_CLASS_HASH=$(starkli declare \
  --account $STARKNET_ACCOUNT --keystore $STARKNET_KEYSTORE \
  --watch target/dev/yab_Escrow.contract_class.json)

echo -e "${GREEN}\n=> [SN] Escrow Declared${COLOR_RESET}"

echo -e "- ${PURPLE}[SN] Escrow ClassHash: $ESCROW_CLASS_HASH${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Herodotus Facts Registry: $HERODOTUS_FACTS_REGISTRY${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Market Maker: $MM_SN_WALLET_ADDR${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Ethereum ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Ethereum ContractAddress: $ETH_CONTRACT_ADDR${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Market Maker: $MM_ETHEREUM_WALLET${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Deploying Escrow${COLOR_RESET}"
ESCROW_CONTRACT_ADDRESS=$(starkli deploy \
  --account $STARKNET_ACCOUNT --keystore $STARKNET_KEYSTORE \
  --watch $ESCROW_CLASS_HASH \
    $SN_ESCROW_OWNER \
    $HERODOTUS_FACTS_REGISTRY \
    $ETH_CONTRACT_ADDR \
    $MM_ETHEREUM_WALLET \
    $MM_SN_WALLET_ADDR \
    $NATIVE_TOKEN_ETH_STARKNET)

echo -e "${GREEN}\n=> [SN] Escrow Deployed${COLOR_RESET}"

echo -e "- ${PURPLE}[SN] Escrow ContractAddress: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}"

sed -i "s/^ESCROW_CONTRACT_ADDRESS=.*/ESCROW_CONTRACT_ADDRESS=$ESCROW_CONTRACT_ADDRESS/" ".env" || echo "ESCROW_CONTRACT_ADDRESS=$ESCROW_CONTRACT_ADDRESS" >> ".env"
