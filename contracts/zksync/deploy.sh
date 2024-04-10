#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

cd ./contracts/zksync/

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

DEPLOY="deploy"
if [ "$TEST" = "true" ]; then
    DEPLOY="deploy-devnet"
fi

echo test
echo $TEST

echo deploy
echo $DEPLOY

DEPLOY="deploy-devnet"

export WALLET_PRIVATE_KEY=$WALLET_PRIVATE_KEY
export PAYMENT_REGISTRY_PROXY_ADDRESS=$PAYMENT_REGISTRY_PROXY_ADDRESS
export MM_ZKSYNC_WALLET=$MM_ZKSYNC_WALLET

# ZKSYNC_ESCROW_CONTRACT_ADDRESS=$(yarn $DEPLOY | grep "Contract address:" | egrep -i -o '0x[a-zA-Z0-9]{40}')
echo "deploying zksync escrow"

RESULT_LOG=$(yarn $DEPLOY)
echo $RESULT_LOG

ZKSYNC_ESCROW_CONTRACT_ADDRESS=$(echo "$RESULT_LOG" | grep "Contract address:" | egrep -i -o '0x[a-zA-Z0-9]{40}')

if [ -z "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ZKSYNC_ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${CYAN}[ZKSync] Escrow Address: $ZKSYNC_ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"
printf "\nIf you now wish to finish the configuration of this deploy, you will need to run the following commands:\n"
echo "export PAYMENT_REGISTRY_PROXY_ADDRESS=$PAYMENT_REGISTRY_PROXY_ADDRESS"
echo "export ZKSYNC_ESCROW_CONTRACT_ADDRESS=$ZKSYNC_ESCROW_CONTRACT_ADDRESS"
echo "make zksync-connect"

cd ../..

