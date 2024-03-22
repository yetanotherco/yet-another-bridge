#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

#fee=24044002524012
FEE=25000000000000
APPROVE_AMOUNT=$((${AMOUNT}+${FEE}))

echo -e "${GREEN}\n=> [SN] Making SetOrder on Escrow${COLOR_RESET}"

starkli invoke \
  $NATIVE_TOKEN_ETH_STARKNET approve $ESCROW_CONTRACT_ADDRESS u256:$APPROVE_AMOUNT \
  / $ESCROW_CONTRACT_ADDRESS set_order 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  u256:$AMOUNT u256:$FEE --private-key $STARKNET_PRIVATE_KEY --account $STARKNET_ACCOUNT
  

# starkli invoke \
#   0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 approve $ESCROW_CONTRACT_ADDRESS u256:2000000 \
#   / $ESCROW_CONTRACT_ADDRESS set_order 0xda963fA72caC2A3aC01c642062fba3C099993D56 \
#   u256:1000000 u256:1000 --keystore /Users/urix/.starkli-wallets/keystore_account_sepolia.json \
#   --account /Users/urix/.starkli-wallets/account_sepolia.json --rpc https://starknet-sepolia.blastapi.io/2e4b6996-7a05-4a49-b3f2-c7a385d68950/rpc/v0_6
