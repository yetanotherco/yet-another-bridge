#!/bin/bash

# ANSI format
GREEN='\e[32m'
COLOR_RESET='\033[0m'

cd "$(dirname "$0")"

load_env() {
    unamestr=$(uname)
    if [ "$unamestr" = 'Linux' ]; then
      export $(grep -v '^#' ./.env | xargs -d '\n')
    elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
      export $(grep -v '^#' ./.env | xargs -0)
    fi
}
load_env

echo -e "${GREEN}\n=> [ETH] Deploy Escrow${COLOR_RESET}"
forge script ./script/Deploy.s.sol --fork-url $GOERLI_RPC_URL --broadcast --verify -vvvv
