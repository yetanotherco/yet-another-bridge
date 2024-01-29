#!/bin/bash

# ANSI format
GREEN='\e[32m'
PURPLE='\033[1;34m'
PINK='\033[1;35m'
ORANGE='\033[1;33m'
COLOR_RESET='\033[0m'

echo -e "${GREEN}\n=> [SN] Declaring Escrow${COLOR_RESET}"
ESCROW_CLASS_HASH=$(starkli declare \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch contracts/cairo/target/dev/yab_Escrow.contract_class.json)

echo -e "${GREEN}\n=> [SN] Escrow Declared${COLOR_RESET}"

echo -e "- ${PURPLE}[SN] Escrow ClassHash: $ESCROW_CLASS_HASH${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Market Maker: $MM_SN_WALLET_ADDR${COLOR_RESET}"
echo -e "- ${PURPLE}[SN] Ethereum ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Ethereum ContractAddress: $ETH_CONTRACT_ADDR${COLOR_RESET}"
echo -e "- ${PINK}[ETH] Market Maker: $MM_ETHEREUM_WALLET${COLOR_RESET}"

echo -e "${GREEN}\n=> [SN] Deploying Escrow${COLOR_RESET}"
ESCROW_CONTRACT_ADDRESS=$(starkli deploy \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch $ESCROW_CLASS_HASH \
    $SN_ESCROW_OWNER \
    $ETH_CONTRACT_ADDR \
    $MM_ETHEREUM_WALLET \
    $MM_SN_WALLET_ADDR \
    $NATIVE_TOKEN_ETH_STARKNET)

echo -e "${GREEN}\n=> [SN] Escrow Deployed${COLOR_RESET}"

echo -e "- ${PURPLE}[SN] Escrow ContractAddress: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}"

# if grep -q "^ESCROW_CONTRACT_ADDRESS=" ".env"; then
#   sed "s/^ESCROW_CONTRACT_ADDRESS=.*/ESCROW_CONTRACT_ADDRESS=$ESCROW_CONTRACT_ADDRESS/" .env >> env.temp.file
#   mv env.temp.file .env
# else
#   echo "ESCROW_CONTRACT_ADDRESS=$ESCROW_CONTRACT_ADDRESS" >> ".env"
# fi