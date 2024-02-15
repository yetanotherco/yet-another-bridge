#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

cd contracts/ethereum

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$ETH_PRIVATE_KEY" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ETH_PRIVATE_KEY Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Upgrading PaymentRegistry ${COLOR_RESET}\n"

RESULT_LOG=$(forge script ./script/Upgrade.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '0: address \K[^\n]+' | awk '{print $0}')
PAYMENT_REGISTRY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '1: address \K[^\n]+' | awk '{print $0}')

if [ -z "$PAYMENT_REGISTRY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Unchanged PaymentRegistry Proxy address: $PAYMENT_REGISTRY_PROXY_ADDRESS ${COLOR_RESET}\n"
printf "${GREEN}\n=> [ETH] Newly Deployed PaymentRegistry contract address: $PAYMENT_REGISTRY_ADDRESS ${COLOR_RESET}\n"

cd ../..
