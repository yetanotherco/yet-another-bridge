#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

cd ./contracts/zksync/

ZKSYNC_ESCROW_CONTRACT_ADDRESS=$(yarn deploy | grep "Contract address:" | egrep -i -o '0x[a-zA-Z0-9]{40}')

if [ -z "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ZKSYNC_ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${CYAN}[ZKSync] Escrow Address: $ZKSYNC_ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"
printf "\nIf you now wish to finish the configuration of this deploy, you will need to run the following commands:\n"
# echo "export PAYMENT_REGISTRY_PROXY_ADDRESS=$PAYMENT_REGISTRY_PROXY_ADDRESS"
echo "export ZKSYNC_ESCROW_CONTRACT_ADDRESS=$ZKSYNC_ESCROW_CONTRACT_ADDRESS"
echo "make zksync-connect"

cd ../..

