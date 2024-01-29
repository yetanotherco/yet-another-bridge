#!/bin/bash

# ANSI format
GREEN='\e[32m'
PURPLE='\033[1;34m'
PINK='\033[1;35m'
ORANGE='\033[1;33m'
COLOR_RESET='\033[0m'

echo -e "${GREEN}\n=> [SN] Declaring ERC20${COLOR_RESET}"
ERC20_CLASS_HASH=$(starkli declare \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch contracts/cairo/target/dev/yab_ERC20.contract_class.json)

echo -e "${GREEN}\n=> [SN] ERC20 Declared${COLOR_RESET}"

echo -e "- ${PURPLE}[SN] ERC20 ClassHash: $ERC20_CLASS_HASH${COLOR_RESET}"
#echo -e "- ${PURPLE}[SN] Market Maker: $MM_SN_WALLET_ADDR${COLOR_RESET}"
#echo -e "- ${PURPLE}[SN] Ethereum ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}"
#echo -e "- ${PINK}[ETH] Ethereum ContractAddress: $ETH_CONTRACT_ADDR${COLOR_RESET}"
#echo -e "- ${PINK}[ETH] Market Maker: $MM_ETHEREUM_WALLET${COLOR_RESET}"

# name: TYAB
# symbol: $YAB
# supply: 4000000000000000000
# recipent: Katana account
# https://www.stark-utils.xyz/converter
echo -e "${GREEN}\n=> [SN] Deploying ERC20${COLOR_RESET}"
NATIVE_TOKEN_ETH_STARKNET=$(starkli deploy \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch $ERC20_CLASS_HASH \
  1415135554 \
  609829186 \
  u256:4000000000000000000 \
  $STARKNET_ACCOUNT_ADDRESS)

echo -e "${GREEN}\n=> [SN] ERC20 Deployed${COLOR_RESET}"

echo -e "- ${PURPLE}[SN] ERC20 ContractAddress: $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}"

# if grep -q "^ERC20_CONTRACT_ADDRESS=" ".env"; then
#   sed "s/^ERC20_CONTRACT_ADDRESS=.*/ERC20_CONTRACT_ADDRESS=$ERC20_CONTRACT_ADDRESS/" .env >> env.temp.file
#   mv env.temp.file .env
# else
#   echo "ERC20_CONTRACT_ADDRESS=$ERC20_CONTRACT_ADDRESS" >> ".env"
# fi