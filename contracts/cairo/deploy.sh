#!/bin/bash

HERODOTUS_FACTS_REGISTRY=0x01b2111317EB693c3EE46633edd45A4876db14A3a53ACDBf4E5166976d8e869d
MM_ETHEREUM_WALLET=0xE8504996d2e25735FA88B3A0a03B4ceD2d3086CC
NATIVE_TOKEN_ETH_STARKNET=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7

cd "$(dirname "$0")"

load_env() {
    unamestr=$(uname)
    if [ "$unamestr" = 'Linux' ]; then
      export $(grep -v '^#' ../../mm-bot/.env | xargs -d '\n')
    elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
      export $(grep -v '^#' ../../mm-bot/.env | xargs -0)
    fi
}
load_env

CLASS_HASH=`starkli declare --rpc $SN_RPC_URL target/dev/yab_Escrow.sierra.json 2>&1 | grep -A1 "Class hash" | sed '1d'`

echo $CLASS_HASH
echo $HERODOTUS_FACTS_REGISTRY
echo $ETH_CONTRACT_ADDR
echo $MM_ETHEREUM_WALLET
echo $SN_WALLET_ADDR
echo $NATIVE_TOKEN_ETH_STARKNET

CONTRACT_ADDRESS=`starkli deploy --rpc $SN_RPC_URL $CLASS_HASH $HERODOTUS_FACTS_REGISTRY $ETH_CONTRACT_ADDR $MM_ETHEREUM_WALLET $SN_WALLET_ADDR $NATIVE_TOKEN_ETH_STARKNET 2>&1 | grep -A1 "Contract deployed" | sed '1d'`

echo $CONTRACT_ADDRESS
