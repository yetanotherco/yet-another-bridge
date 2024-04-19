#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

cd contracts/ethereum

printf "${GREEN}\n=> [ETH] Deploying ERC20 ${COLOR_RESET}\n"


export ETHEREUM_PRIVATE_KEY=$ETHEREUM_PRIVATE_KEY

RESULT_LOG=$(forge script ./script/Deploy_ERC20.s.sol --rpc-url $ETHEREUM_RPC --broadcast ${SKIP_VERIFY:---verify})
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# Getting result addresses
ERC20_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')

if [ -z "$ERC20_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ERC20_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Deployed ERC20 address: $ERC20_ADDRESS ${COLOR_RESET}\n"

cd ../.. #to reset working directory
