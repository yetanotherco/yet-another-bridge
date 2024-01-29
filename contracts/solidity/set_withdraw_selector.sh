#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

echo -e "${GREEN}\n=> [ETH] Setting Starknet Withdraw Selector on ETH Smart Contract${COLOR_RESET}"
echo "Smart contract being modified:" $YAB_TRANSFER_PROXY_ADDRESS

WITHDRAW_SELECTOR=$(starkli selector $WITHDRAW_NAME)
echo "New Withdraw Selector: ${WITHDRAW_SELECTOR}"

#why the following grep?
cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $YAB_TRANSFER_PROXY_ADDRESS "setEscrowWithdrawSelector(uint256)" "${WITHDRAW_SELECTOR}" | grep "transactionHash"
