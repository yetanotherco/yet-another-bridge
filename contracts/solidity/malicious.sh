#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

if [ -z "$ESCROW_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ESCROW_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$CLAIM_PAYMENT_SELECTOR" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "CLAIM_PAYMENT_SELECTOR Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$SN_MESSAGING_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "SN_MESSAGING_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$STARKNET_ACCOUNT" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_ACCOUNT Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$STARKNET_KEYSTORE" ]; then
    echo "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_KEYSTORE Variable is empty. Aborting execution.\n"
    exit 1
fi


# 1 deploy-all
# 2 deploy malicious
# 3 set orders on Escrow 
# 4 do transfers on PaymentRegistry
# 5 call malicious.steal_from_PaymentRegistry
# 6 call malicious.steal_from_Escrow

# 1 deploy-all
# make deploy-all #this can be disabled while the contracts don't change

# 2 deploy malicious
cd contracts/solidity

# printf "${GREEN}\n=> [ETH] Deploying Malicious Contract ${COLOR_RESET}\n"

# RESULT_LOG=$(forge script ./script/Deploy_Malicious.s.sol --rpc-url $ETH_RPC_URL --broadcast ${SKIP_VERIFY:---verify} -vvvv)
# echo "$RESULT_LOG" #uncomment this line for debugging in detail

# MALICIOUS_ADDRESS=$(echo "$RESULT_LOG" | grep -Eo '0: address ([^\n]+)' | awk '{print $NF}')

# if [ -z "$MALICIOUS_ADDRESS" ]; then
#     printf "\n${RED}ERROR:${COLOR_RESET}\n"
#     echo "MALICIOUS_ADDRESS Variable is empty. Aborting execution.\n"
#     exit 1
# fi

# printf "${GREEN}\n=> [ETH] Deployed Malicious address: $MALICIOUS_ADDRESS ${COLOR_RESET}\n"


# printf "${GREEN}\n=> [ETH] Setting Escrow Address + Selector on Malicious${COLOR_RESET}\n"

# cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $MALICIOUS_ADDRESS "setEscrowAddress(uint256)" $ESCROW_CONTRACT_ADDRESS | grep "transactionHash"
# CLAIM_PAYMENT_SELECTOR=$(starkli selector $CLAIM_PAYMENT_NAME)
# cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $MALICIOUS_ADDRESS "setEscrowClaimPaymentSelector(uint256)" "${CLAIM_PAYMENT_SELECTOR}" | grep "transactionHash"

MALICIOUS_ADDRESS=0xD7659274b6Ed72Ec6D9f8fA1ad45B5476856e0CF
AMOUNT=10000000000000000 #0.01 ETH
FEE=25000000000000 #0.000025
APPROVE_AMOUNT=$((${AMOUNT}+${FEE}))
# 3 set orders on Escrow
printf "${GREEN}\n=> [SN] Setting orders on Escrow${COLOR_RESET}\n"

# printf "${GREEN}\n=> [ETH] Executing Steal jobs on Malicious${COLOR_RESET}\n"
 starkli invoke \
  $NATIVE_TOKEN_ETH_STARKNET approve $ESCROW_CONTRACT_ADDRESS u256:$APPROVE_AMOUNT \
  / $ESCROW_CONTRACT_ADDRESS set_order 0xB321099cf86D9BB913b891441B014c03a6CcFc54 \
  u256:$AMOUNT u256:$FEE --account $STARKNET_ACCOUNT --keystore $STARKNET_KEYSTORE
#   --private-key $STARKNET_PRIVATE_KEY 




#   --private-key $STARKNET_PRIVATE_KEY --account $STARKNET_ACCOUNT

cd ../.. #to reset working directory

