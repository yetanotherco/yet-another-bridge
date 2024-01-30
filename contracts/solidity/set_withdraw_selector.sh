#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

if [ -z "$YAB_TRANSFER_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}"
    echo "YAB_TRANSFER_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

if [ -z "$WITHDRAW_NAME" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}"
    echo "WITHDRAW_NAME Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Setting Starknet Withdraw Selector on ETH Smart Contract${COLOR_RESET}"
echo "Smart contract being modified:" $YAB_TRANSFER_PROXY_ADDRESS

WITHDRAW_SELECTOR=$(starkli selector $WITHDRAW_NAME)
echo "New Withdraw Selector: ${WITHDRAW_SELECTOR}"

cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $YAB_TRANSFER_PROXY_ADDRESS "setEscrowWithdrawSelector(uint256)" "${WITHDRAW_SELECTOR}" | grep "transactionHash"
