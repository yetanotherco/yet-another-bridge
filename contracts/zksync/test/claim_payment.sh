#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making Claim Payment${COLOR_RESET}\n"

MM_INITIAL_BALANCE_L1=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_WALLET_ADDRESS)
echo "Initial MM balance L1:"
echo "$MM_INITIAL_BALANCE_L1"

echo "Initial MM balance L2:"
npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$MM_ZKSYNC_WALLET"

echo "Initial Escrow balance:"
npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS"


echo "Withdrawing $BRIDGE_AMOUNT_ETH ETH"
echo "Withdrawing $BRIDGE_AMOUNT_WEI WEI"

cast send --rpc-url $ETHEREUM_RPC --private-key $ETHEREUM_PRIVATE_KEY --gas-price 2000000000 \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "claimPaymentZKSync(uint256, address, uint256, uint256, uint256)" \
  "0" $USER_ETHEREUM_PUBLIC_ADDRESS $BRIDGE_AMOUNT_WEI 2000000 800 \
  --value 5000000000000000000

MM_INITIAL_BALANCE_L1=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_WALLET_ADDRESS)
echo "After MM balance L1:"
echo "$MM_INITIAL_BALANCE_L1"

echo "After MM balance L2:"
npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$MM_ZKSYNC_WALLET"

echo "After Escrow balance:"
npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS"
