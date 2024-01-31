#!/bin/bash
. contracts/general/colors.sh #for ANSI colors

if [ -z "$YAB_TRANSFER_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "YAB_TRANSFER_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi


printf "${GREEN}\n=> [ETH] Setting Starknet Escrow Address on ETH Smart Contract${COLOR_RESET}\n"

echo "Smart contract being modified:" $YAB_TRANSFER_PROXY_ADDRESS
echo "New Escrow address:" $ESCROW_CONTRACT_ADDRESS

cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $YAB_TRANSFER_PROXY_ADDRESS "setEscrowAddress(uint256)" $ESCROW_CONTRACT_ADDRESS | grep "transactionHash"
echo "Done setting escrow address"
