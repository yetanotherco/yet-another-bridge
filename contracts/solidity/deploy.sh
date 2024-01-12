#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

load_env() {
    unamestr=$(uname)
    if [ "$unamestr" = 'Linux' ]; then
      export $(sed '/^#/d; s/#.*$//' .env | xargs -d '\n')
    elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
      export $(sed '/^#/d; s/#.*$//' .env | xargs -0)
    fi
}
load_env

echo -e "${GREEN}\n=> [ETH] Deploy ERC1967Proxy & YABTransfer ${COLOR_RESET}"
RESULT_LOG=$(forge script ./script/Deploy.s.sol --rpc-url $ETH_RPC_URL --broadcast --verify --private-key $ETH_PRIVATE_KEY)

# Setting result address into .env file
YAB_TRANSFER_PROXY_ADDRESS=$(echo "$RESULT_LOG" | grep -oP '0: address \K[^\n]+' | awk '{print $0}')
echo -e "${GREEN}\n=> [ETH] Deployed Proxy address: $YAB_TRANSFER_PROXY_ADDRESS ${COLOR_RESET}"
sed -i "s/^YAB_TRANSFER_PROXY_ADDRESS=.*/YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS/" ".env" || echo "YAB_TRANSFER_PROXY_ADDRESS=$YAB_TRANSFER_PROXY_ADDRESS" >> ".env"
