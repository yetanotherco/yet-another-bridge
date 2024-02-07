#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$CLAIM_PAYMENT_NAME" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "CLAIM_PAYMENT_NAME Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Setting Starknet ClaimPayment Selector on ETH Smart Contract${COLOR_RESET}\n"
echo "Smart contract being modified:" $PAYMENT_REGISTRY_PROXY_ADDRESS

CLAIM_PAYMENT_SELECTOR=$(starkli selector $CLAIM_PAYMENT_NAME)
echo "New ClaimPayment Selector: ${CLAIM_PAYMENT_SELECTOR}"

cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $PAYMENT_REGISTRY_PROXY_ADDRESS "setEscrowClaimPaymentSelector(uint256)" "${CLAIM_PAYMENT_SELECTOR}" | grep "transactionHash"
echo "Done setting ClaimPayment selector"
