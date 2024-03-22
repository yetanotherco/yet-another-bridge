#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

# export DESTINATION_ADDRESS=0xceee57f2b700c2f37d1476a7974965e149fce2d4
# export DESTINATION_ADDRESS_UINT=1181367337507422765615536123397692015769584198356

printf "${GREEN}\n=> [ETH] Making transfer to Destination account${COLOR_RESET}\n"

MM_INITIAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_PUBLIC_ADDRESS)
DESTINATION_INITIAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $USER_ETHEREUM_PUBLIC_ADDRESS)
echo "Initial MM balance: $MM_INITIAL_BALANCE"
echo "Initial Destination balance: $DESTINATION_INITIAL_BALANCE"


echo "Transferring $BRIDGE_AMOUNT_WEI WEI to $USER_ETHEREUM_PUBLIC_ADDRESS"

cast send --rpc-url $ETHEREUM_RPC --private-key $MM_ETHEREUM_PRIVATE_KEY \
  $PAYMENT_REGISTRY_PROXY_ADDRESS "transfer(uint256, uint256, uint8)" \
  "0" "$USER_ETHEREUM_PUBLIC_ADDRESS_UINT" "1"\
  --value $BRIDGE_AMOUNT_WEI >> /dev/null



MM_FINAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $MM_ETHEREUM_PUBLIC_ADDRESS)
DESTINATION_FINAL_BALANCE=$(cast balance --rpc-url $ETHEREUM_RPC --ether $USER_ETHEREUM_PUBLIC_ADDRESS)
echo "Final MM balance: $MM_FINAL_BALANCE"
echo "Final Destination balance: $DESTINATION_FINAL_BALANCE"
