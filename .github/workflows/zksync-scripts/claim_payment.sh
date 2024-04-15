#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making Claim Payment${COLOR_RESET}\n"

BALANCE_ESCROW_L2_BEFORE_CLAIMPAYMENT=$(cast balance --rpc-url http://localhost:3050 $ZKSYNC_ESCROW_CONTRACT_ADDRESS)
echo "\nInitial Escrow balance: $BALANCE_ESCROW_L2_BEFORE_CLAIMPAYMENT"

# BALANCE_MM_L1_BEFORE_CLAIMPAYMENT=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
# echo "\nInitial MM balance: $BALANCE_MM_L1_BEFORE_CLAIMPAYMENT"

BALANCE_MM_L2_BEFORE_CLAIMPAYMENT_WEI=$(cast balance --rpc-url http://localhost:3050 $MM_ZKSYNC_WALLET)
BALANCE_MM_L2_BEFORE_CLAIMPAYMENT=$(cast balance --rpc-url http://localhost:3050 --ether $MM_ZKSYNC_WALLET)
echo "\nInitial MM balance: $BALANCE_MM_L2_BEFORE_CLAIMPAYMENT"

echo "Withdrawing $BRIDGE_AMOUNT_ETH ETH" # == $BRIDGE_AMOUNT_WEI WEI"
cast send --rpc-url $ETHEREUM_RPC --private-key $ETHEREUM_PRIVATE_KEY --gas-price 2000000000 \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "claimPaymentZKSync(uint256, address, uint256, uint256, uint256)" \
  "0" $USER_ETHEREUM_PUBLIC_ADDRESS $BRIDGE_AMOUNT_WEI 2000000 800 \
  --value 5000000000000000000 > /dev/null

# echo "\nMM L1 funds after Claim Payment"
# BALANCE_MM_L1_AFTER_CLAIMPAYMENT=$(cast balance --rpc-url $ETHEREUM_RPC $MM_ETHEREUM_WALLET_ADDRESS)
# echo "$BALANCE_MM_L1_AFTER_CLAIMPAYMENT"

BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT_WEI=$(cast balance --rpc-url http://localhost:3050 $ZKSYNC_ESCROW_CONTRACT_ADDRESS)
BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT=$(cast balance --rpc-url http://localhost:3050 --ether $ZKSYNC_ESCROW_CONTRACT_ADDRESS)
echo "\nFinal Escrow balance: $BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT"

BALANCE_MM_L2_AFTER_CLAIMPAYMENT_WEI=$(cast balance --rpc-url http://localhost:3050 $MM_ZKSYNC_WALLET)
BALANCE_MM_L2_AFTER_CLAIMPAYMENT=$(cast balance --rpc-url http://localhost:3050 --ether $MM_ZKSYNC_WALLET)
echo "\nFinal MM balance:$BALANCE_MM_L2_AFTER_CLAIMPAYMENT"
