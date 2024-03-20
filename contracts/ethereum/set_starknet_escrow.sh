#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi


printf "${GREEN}\n=> [ETH] Setting Starknet Escrow Address on ETH Smart Contract${COLOR_RESET}\n"

echo "Smart contract being modified:" $PAYMENT_REGISTRY_PROXY_ADDRESS
echo "New Escrow address:" $ESCROW_CONTRACT_ADDRESS

cast send --rpc-url $ETHEREUM_RPC --private-key $ETHEREUM_PRIVATE_KEY $PAYMENT_REGISTRY_PROXY_ADDRESS "setStarknetEscrowAddress(uint256)" $ESCROW_CONTRACT_ADDRESS | grep "transactionHash"
echo "Done setting escrow address"
