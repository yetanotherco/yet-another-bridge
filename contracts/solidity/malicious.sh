#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

# 1 deploy-all
# 2 deploy malicious
# 3 call malicious.steal_from_PaymentRegistry
# 4 call malicious.steal_from_Escrow

# 1
# make deploy-all

# 2
cd contracts/solidity

printf "${GREEN}\n=> [ETH] Deploying Malicious Contract ${COLOR_RESET}\n"

RESULT_LOG=$(forge script ./script/Deploy_Malicious.s.sol --rpc-url $ETH_RPC_URL --broadcast ${SKIP_VERIFY:---verify})
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

MALICIOUS_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')

if [ -z "$MALICIOUS_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "MALICIOUS_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [ETH] Deployed Malicious address: $MALICIOUS_ADDRESS ${COLOR_RESET}\n"

cd ../.. #to reset working directory

