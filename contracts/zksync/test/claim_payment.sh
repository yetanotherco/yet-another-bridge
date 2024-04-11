#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making Claim Payment${COLOR_RESET}\n"

echo "Initial MM balance L1:"
BALANCE_MM_L1_BEFORE_CLAIMPAYMENT=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
echo "$BALANCE_MM_L1_BEFORE_CLAIMPAYMENT"

echo "Initial MM balance L2:"
BALANCE_MM_L2_BEFORE_CLAIMPAYMENT=$(npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$MM_ZKSYNC_WALLET" | grep -oE '[0-9]+\.[0-9]+' | sed 's/\.//g')
echo $BALANCE_MM_L2_BEFORE_CLAIMPAYMENT

echo "Initial Escrow balance:"
BALANCE_ESCROW_L2_BEFORE_CLAIMPAYMENT=$(npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" | grep -oE '[0-9]+\.[0-9]+' | sed 's/\.//g')
echo $BALANCE_ESCROW_L2_BEFORE_CLAIMPAYMENT

echo "Withdrawing $BRIDGE_AMOUNT_ETH ETH"
echo "Withdrawing $BRIDGE_AMOUNT_WEI WEI"

cast send --rpc-url $ETHEREUM_RPC --private-key $ETHEREUM_PRIVATE_KEY --gas-price 2000000000 \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "claimPaymentZKSync(uint256, address, uint256, uint256, uint256)" \
  "0" $USER_ETHEREUM_PUBLIC_ADDRESS $BRIDGE_AMOUNT_WEI 2000000 800 \
  --value 5000000000000000000

echo "After MM balance L1:"
BALANCE_MM_L1_AFTER_CLAIMPAYMENT=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
echo "$BALANCE_MM_L1_AFTER_CLAIMPAYMENT"

echo "After MM balance L2:"
BALANCE_MM_L2_AFTER_CLAIMPAYMENT=$(npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$MM_ZKSYNC_WALLET" | grep -oE '[0-9]+\.[0-9]+' | sed 's/\.//g')
echo $BALANCE_MM_L2_AFTER_CLAIMPAYMENT

echo "After Escrow balance:"
BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT=$(npx zksync-cli wallet balance --rpc http://localhost:3050 --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" | grep -oE '[0-9]+\.[0-9]+' | sed 's/\.//g')
