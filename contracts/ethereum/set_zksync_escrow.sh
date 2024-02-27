#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ZKSYNC_ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi


printf "${GREEN}\n=> [ETH] Setting ZKSync Escrow Address on ETH Smart Contract${COLOR_RESET}\n"

echo "Smart contract being modified:" $PAYMENT_REGISTRY_PROXY_ADDRESS
echo "New ZKSync Escrow address:" $ZKSYNC_ESCROW_CONTRACT_ADDRESS

cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $PAYMENT_REGISTRY_PROXY_ADDRESS "setZKSyncEscrowAddress(address)" $ZKSYNC_ESCROW_CONTRACT_ADDRESS | grep "transactionHash"
echo "Done setting escrow address"
