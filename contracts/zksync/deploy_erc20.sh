#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

cd ./contracts/zksync/

ERC20_CONTRACT_ADDRESS=$(yarn deploy-erc20 | grep "Contract address:" | egrep -i -o '0x[a-zA-Z0-9]{40}')

if [ -z "$ERC20_CONTRACT_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ERC20_CONTRACT_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${CYAN}[ZKSync] ERC20 Address: $ERC20_CONTRACT_ADDRESS${COLOR_RESET}\n"

cd ../..

