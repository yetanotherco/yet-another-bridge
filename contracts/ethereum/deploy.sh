#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

cd contracts/ethereum

printf "${GREEN}\n=> [ETH] Deploying ERC1967Proxy & PaymentRegistry ${COLOR_RESET}\n"

### These values are not correctly interpreted by the CI environment otherwise.
### Locally, this has no effect
export ETHEREUM_PRIVATE_KEY=$ETHEREUM_PRIVATE_KEY
export ZKSYNC_DIAMOND_PROXY_ADDRESS=$ZKSYNC_DIAMOND_PROXY_ADDRESS
export STARKNET_MESSAGING_ADDRESS=$STARKNET_MESSAGING_ADDRESS
export STARKNET_CLAIM_PAYMENT_SELECTOR=$STARKNET_CLAIM_PAYMENT_SELECTOR
export STARKNET_CLAIM_PAYMENT_BATCH_SELECTOR=$STARKNET_CLAIM_PAYMENT_BATCH_SELECTOR
export MM_ETHEREUM_WALLET_ADDRESS=$MM_ETHEREUM_WALLET_ADDRESS
export ZKSYNC_DIAMOND_PROXY_ADDRESS=$ZKSYNC_DIAMOND_PROXY_ADDRESS
export ZKSYNC_CLAIM_PAYMENT_SELECTOR=$ZKSYNC_CLAIM_PAYMENT_SELECTOR
export ZKSYNC_CLAIM_PAYMENT_BATCH_SELECTOR=$ZKSYNC_CLAIM_PAYMENT_BATCH_SELECTOR
export STARKNET_CHAIN_ID=$STARKNET_CHAIN_ID
export ZKSYNC_CHAIN_ID=$ZKSYNC_CHAIN_ID
###


RESULT_LOG=$(forge script ./script/Deploy.s.sol --rpc-url $ETHEREUM_RPC --broadcast ${SKIP_VERIFY:---verify})
# echo "$RESULT_LOG" #uncomment this line for debugging in detail


# Getting result addresses
PAYMENT_REGISTRY_PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')
PAYMENT_REGISTRY_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '1: address ([^\n]+)' | awk '{print $NF}')

if [ -z "$PAYMENT_REGISTRY_PROXY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$PAYMENT_REGISTRY_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "PAYMENT_REGISTRY_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Deployed Proxy address: $PAYMENT_REGISTRY_PROXY_ADDRESS ${COLOR_RESET}\n"
printf "${GREEN}\n=> [ETH] Deployed PaymentRegistry address: $PAYMENT_REGISTRY_ADDRESS ${COLOR_RESET}\n"

echo "\nIf you now wish to deploy an Escrow, you will need to run the following commands:"
echo "export PAYMENT_REGISTRY_PROXY_ADDRESS=$PAYMENT_REGISTRY_PROXY_ADDRESS"
echo "make starknet-deploy"
echo "OR"
echo "make zksync-deploy"

cd ../.. #to reset working directory
