#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

export STARKNET_RPC=$STARKNET_RPC

if [ -z "$STARKNET_ACCOUNT" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_ACCOUNT Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$STARKNET_KEYSTORE" ] && [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_KEYSTORE and STARKNET_PRIVATE_KEY Variables are empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$MM_STARKNET_WALLET_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "MM_STARKNET_WALLET_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$NATIVE_TOKEN_ETH_STARKNET" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "NATIVE_TOKEN_ETH_STARKNET Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$MM_ETHEREUM_WALLET_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "MM_ETHEREUM_WALLET_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi


echo "${GREEN}\n=> [SN] Declaring Escrow${COLOR_RESET}"
ESCROW_CLASS_HASH=$(starkli declare \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch contracts/cairo/target/dev/yab_Escrow.contract_class.json)


if [ -z "$ESCROW_CLASS_HASH" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ESCROW_CLASS_HASH Variable is empty. Aborting execution.\n"
    exit 1
fi

if [ -z "$STARKNET_ESCROW_OWNER" ]; then
  echo "" #\n
  printf "${ORANGE}WARNING:${COLOR_RESET} no STARKNET_ESCROW_OWNER defined in .env, declaring deployer as the owner of the contract\n"
  STARKNET_ESCROW_OWNER=$(cat "$STARKNET_ACCOUNT" | grep '"address"' | sed -E 's/.*"address": "([^"]+)".*/\1/')
fi


printf "${GREEN}\n=> [SN] Escrow Declared${COLOR_RESET}\n"

printf "${CYAN}[SN] Escrow ClassHash: $ESCROW_CLASS_HASH${COLOR_RESET}\n"
printf "${CYAN}[SN] Market Maker SN Wallet: $MM_STARKNET_WALLET_ADDRESS${COLOR_RESET}\n"
printf "${CYAN}[SN] Ethereum ERC20 ContractAddress $NATIVE_TOKEN_ETH_STARKNET${COLOR_RESET}\n"
printf "${PINK}[ETH] PaymentRegistry Proxy Address: $PAYMENT_REGISTRY_PROXY_ADDRESS${COLOR_RESET}\n"
printf "${PINK}[ETH] Market Maker ETH Wallet: $MM_ETHEREUM_WALLET_ADDRESS${COLOR_RESET}\n"

printf "${GREEN}\n=> [SN] Deploying Escrow${COLOR_RESET}\n"
ESCROW_CONTRACT_ADDRESS=$(starkli deploy \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch $ESCROW_CLASS_HASH \
    $STARKNET_ESCROW_OWNER \
    $PAYMENT_REGISTRY_PROXY_ADDRESS \
    $MM_ETHEREUM_WALLET_ADDRESS \
    $MM_STARKNET_WALLET_ADDRESS \
    $NATIVE_TOKEN_ETH_STARKNET)
echo $ESCROW_CONTRACT_ADDRESS

printf "${GREEN}\n=> [SN] Escrow Deployed${COLOR_RESET}\n"

printf "${CYAN}[SN] Escrow Address: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"

echo "\nIf you now wish to finish the configuration of this deploy, you will need to run the following commands:"
echo "export PAYMENT_REGISTRY_PROXY_ADDRESS=$PAYMENT_REGISTRY_PROXY_ADDRESS"
echo "export ESCROW_CONTRACT_ADDRESS=$ESCROW_CONTRACT_ADDRESS"
echo "make ethereum-set-escrow"
echo "make ethereum-set-claim-payment-selector"
