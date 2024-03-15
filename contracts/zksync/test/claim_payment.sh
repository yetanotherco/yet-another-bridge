#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

printf "${GREEN}\n=> [ETH] Making Claim Payment${COLOR_RESET}\n"

MM_INITIAL_BALANCE_L1=$(cast balance --rpc-url $ETH_RPC_URL --ether $MM_ETHEREUM_PUBLIC_ADDRESS)
echo "Initial MM balance L1:"
echo "$MM_INITIAL_BALANCE_L1"

echo "Initial MM balance L2:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$MM_ZKSYNC_WALLET" | grep -E -o "\d+(\.\d+)? ETH"

echo "Initial Escrow balance:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" | grep -E -o "\d+(\.\d+)? ETH"


echo "Withdrawing $BRIDGE_AMOUNT_ETH ETH"
echo "Withdrawing $BRIDGE_AMOUNT_WEI WEI"

cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "claimPaymentZKSync(uint256, uint256, uint256, uint256, uint256)" \
  "0" "$USER_ETHEREUM_PUBLIC_ADDRESS_UINT" "$BRIDGE_AMOUNT_WEI" "2000000000" "800"\
  --value 5000000000000000000

#ele pe eme
#me revertea con info: None
#no estoy seguro si existe un diamond proxy en la dada address.



sleep 15


MM_INITIAL_BALANCE_L1=$(cast balance --rpc-url $ETH_RPC_URL --ether $MM_ETHEREUM_PUBLIC_ADDRESS)
echo "After MM balance L1:"
echo "$MM_INITIAL_BALANCE_L1"

echo "After MM balance L2:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$MM_ZKSYNC_WALLET" | grep -E -o "\d+(\.\d+)? ETH"

echo "After Escrow balance:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" | grep -E -o "\d+(\.\d+)? ETH"



# starkli call $ESCROW_CONTRACT_ADDRESS get_order_pending u256:0

# ESCROW_FINAL_BALANCE=$(starkli balance $ESCROW_CONTRACT_ADDRESS)
# MM_FINAL_BALANCE=$(starkli balance $MM_SN_WALLET_ADDR)
# echo "Final Escrow balance: $ESCROW_FINAL_BALANCE"
# echo "Final MM balance: $MM_FINAL_BALANCE"
