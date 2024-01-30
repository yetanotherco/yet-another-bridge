#!/bin/bash

# ANSI format
GREEN='\e[32m'
CYAN='\033[36m'
PINK='\033[1;35m'
ORANGE='\033[1;33m'
RED='\033[0;31m'
COLOR_RESET='\033[0m'

#todo: make this prettier
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
if [ -z "$MM_SN_WALLET_ADDR" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "MM_SN_WALLET_ADDR Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$NATIVE_TOKEN_ETH_STARKNET" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "NATIVE_TOKEN_ETH_STARKNET Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$YAB_TRANSFER_PROXY_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "YAB_TRANSFER_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$MM_ETHEREUM_WALLET" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "MM_SN_MM_ETHEREUM_WALLETWALLET_ADDR Variable is empty. Aborting execution.\n"
    exit 1
fi


echo "${GREEN}\n=> [SN] Declaring Escrow${COLOR_RESET}"
ESCROW_CLASS_HASH=$(starkli declare \
  --account $STARKNET_ACCOUNT --keystore $STARKNET_KEYSTORE \
  --watch contracts/cairo/target/dev/yab_Escrow.contract_class.json)


if [ -z "$ESCROW_CLASS_HASH" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ESCROW_CLASS_HASH Variable is empty. Aborting execution.\n"
    exit 1
fi

if [ -z "$SN_ESCROW_OWNER" ]; then
  echo "" #\n
  printf "${ORANGE}WARNING:${COLOR_RESET} no SN_ESCROW_OWNER defined in .env, declaring deployer as the owner of the contract\n"
  SN_ESCROW_OWNER=$(cat "$STARKNET_ACCOUNT" | grep '"address"' | sed -E 's/.*"address": "([^"]+)".*/\1/')
fi


printf "${GREEN}\n=> [SN] Escrow Declared${COLOR_RESET}\n"

printf "${CYAN}[SN] Escrow ClassHash: $ESCROW_CLASS_HASH${COLOR_RESET}\n"
printf "${CYAN}[SN] Market Maker SN Wallet: $MM_SN_WALLET_ADDR${COLOR_RESET}\n"
printf "${CYAN}[SN] Ethereum ERC20 ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}\n"
printf "${PINK}[ETH] YABTransfer Proxy Address: $YAB_TRANSFER_PROXY_ADDRESS${COLOR_RESET}\n"
printf "${PINK}[ETH] Market Maker ETH Wallet: $MM_ETHEREUM_WALLET${COLOR_RESET}\n"

printf "${GREEN}\n=> [SN] Deploying Escrow${COLOR_RESET}\n"
ESCROW_CONTRACT_ADDRESS=$(starkli deploy \
  --account $STARKNET_ACCOUNT --keystore $STARKNET_KEYSTORE \
  --watch $ESCROW_CLASS_HASH \
    $SN_ESCROW_OWNER \
    $YAB_TRANSFER_PROXY_ADDRESS \
    $MM_ETHEREUM_WALLET \
    $MM_SN_WALLET_ADDR \
    $NATIVE_TOKEN_ETH_STARKNET)

printf "${GREEN}\n=> [SN] Escrow Deployed${COLOR_RESET}\n"

printf "${CYAN}[SN] Escrow Address: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"

echo "If you now wish to finish the configuration of this deploy, you will need to run the following commands:"
echo "export YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS"
echo "export ESCROW_CONTRACT_ADDRESS=$ESCROW_CONTRACT_ADDRESS"
echo "make ethereum-set-escrow"
echo "make ethereum-set-withdraw-selector"