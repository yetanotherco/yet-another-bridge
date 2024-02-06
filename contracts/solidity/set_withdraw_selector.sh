#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$WITHDRAW_NAME" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "WITHDRAW_NAME Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Setting Starknet Withdraw Selector on ETH Smart Contract${COLOR_RESET}\n"
echo "Smart contract being modified:" $PAYMENT_REGISTRY_PROXY_ADDRESS

WITHDRAW_SELECTOR=$(starkli selector $WITHDRAW_NAME)
echo "New Withdraw Selector: ${WITHDRAW_SELECTOR}"

cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $PAYMENT_REGISTRY_PROXY_ADDRESS "setEscrowWithdrawSelector(uint256)" "${WITHDRAW_SELECTOR}" | grep "transactionHash"
echo "Done setting withdraw selector"
