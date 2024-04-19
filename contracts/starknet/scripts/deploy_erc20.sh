#!/bin/bash
. contracts/utils/colors.sh #for ANSI colors

export STARKNET_RPC=$STARKNET_RPC

if [ -z "$STARKNET_ACCOUNT" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_ACCOUNT Variable is empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$STARKNET_KEYSTORE" ] && [ -z "$STARKNET_PRIVATE_KEY" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}"
    echo "STARKNET_KEYSTORE and STARKNET_PRIVATE_KEY Variables are empty. Aborting execution.\n"
    exit 1
fi
if [ -z "$MM_STARKNET_WALLET_ADDRESS" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}"
    echo "MM_STARKNET_WALLET_ADDRESS Variable is empty. Aborting execution.\n"
    exit 1
fi


printf "${GREEN}\n=> [SN] Declaring ERC20${COLOR_RESET}\n"
ERC20_CLASS_HASH=$(starkli declare \
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch contracts/starknet/target/dev/yab_ERC20.contract_class.json)


if [ -z "$ERC20_CLASS_HASH" ]; then
    printf "\n${RED}ERROR:${COLOR_RESET}\n"
    echo "ERC20_CLASS_HASH Variable is empty. Aborting execution.\n"
    exit 1
fi

printf "${GREEN}\n=> [SN] ERC20 Declared${COLOR_RESET}\n"

printf "${CYAN}[SN] ERC20 ClassHash: $ERC20_CLASS_HASH${COLOR_RESET}\n"
# maybe print initial whale
# printf "${PINK}[ETH] Market Maker ETH Wallet: $MM_ETHEREUM_WALLET_ADDRESS${COLOR_RESET}\n"
NAME=0x555249434f494e #'URICOIN'
SYMBOL=0x555249 #'URI'
INITIAL_SUPPLY_low=0x0f4240 # 1000000
INITIAL_SUPPLY_high=0x0 #because INITIAL_SUPPLY is a uint256 and requires 2 params
RECIPIENT=0x078557823d56a27dd29881285ae58efba18a9da536df0a0c674564e4185e7629 #Braavos account 1, user, contract address format is OK

printf "${GREEN}\n=> [SN] Deploying ERC20${COLOR_RESET}\n"
ERC20_CONTRACT_ADDRESS=$(starkli deploy --max-fee-raw 31367442226306\
  --account $STARKNET_ACCOUNT \
  $(if [ -n "$STARKNET_KEYSTORE" ]; then echo "--keystore $STARKNET_KEYSTORE"; fi) \
  $(if [ -n "$STARKNET_PRIVATE_KEY" ]; then echo "--private-key $STARKNET_PRIVATE_KEY"; fi) \
  --watch $ERC20_CLASS_HASH \
    $NAME \
    $SYMBOL \
    $INITIAL_SUPPLY_low $INITIAL_SUPPLY_high \
    $RECIPIENT)
echo $ERC20_CONTRACT_ADDRESS

printf "${GREEN}\n=> [SN] ERC20 Deployed${COLOR_RESET}\n"

printf "${CYAN}[SN] ERC20 Address: $ERC20_CONTRACT_ADDRESS${COLOR_RESET}\n"
