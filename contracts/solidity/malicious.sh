#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

# 1 make deploy-all
# 2 deploy malicious
# 3 call malicious.steal_from_PaymentRegistry
# 4 call malicious.steal_from_Escrow

make deploy-all



# if [ -z "$YAB_TRANSFER_PROXY_ADDRESS" ]; then
#     printf "\n${RED}ERROR:${COLOR_RESET}\n"
#     echo "YAB_TRANSFER_PROXY_ADDRESS Variable is empty. Aborting execution.\n"
#     exit 1
# fi
# if [ -z "$ETH_PRIVATE_KEY" ]; then
#     printf "\n${RED}ERROR:${COLOR_RESET}\n"
#     echo "ETH_PRIVATE_KEY Variable is empty. Aborting execution.\n"
#     exit 1
# fi

# printf "${GREEN}\n=> [ETH] Upgrading YABTransfer ${COLOR_RESET}\n"

# RESULT_LOG=$(forge script ./script/Upgrade.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify)
# # echo "$RESULT_LOG" #uncomment this line for debugging in detail

# # Getting result addresses
# PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '0: address \K[^\n]+' | awk '{print $0}')
# YAB_TRANSFER_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '1: address \K[^\n]+' | awk '{print $0}')

# if [ -z "$YAB_TRANSFER_ADDRESS" ]; then
#     printf "\n${RED}ERROR:${COLOR_RESET}\n"
#     echo "YAB_TRANSFER_ADDRESS Variable is empty. Aborting execution.\n"
#     exit 1
# fi

# printf "${GREEN}\n=> [ETH] Unchanged YABTransfer Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}\n"
# printf "${GREEN}\n=> [ETH] Newly Deployed YABTransfer contract address: $YAB_TRANSFER_ADDRESS ${COLOR_RESET}\n"
