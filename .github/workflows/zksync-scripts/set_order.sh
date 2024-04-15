#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

FEE=10000000000000000 #in WEI
VALUE=2 #in ETH
VALUE_WEI=$(echo "scale=0; $VALUE * 10^18" | bc)
BRIDGE_AMOUNT_WEI=$(echo "scale=0; $VALUE_WEI - $FEE" | bc)
BRIDGE_AMOUNT_ETH=$(echo "scale=18; $BRIDGE_AMOUNT_WEI / 10^18" | bc)

echo USER_ZKSYNC_PUBLIC_ADDRESS
echo $USER_ZKSYNC_PUBLIC_ADDRESS
echo ZKSYNC_ESCROW_CONTRACT_ADDRESS
echo $ZKSYNC_ESCROW_CONTRACT_ADDRESS

printf "${GREEN}\n=> [SN] Making Set Order on Escrow${COLOR_RESET}\n"
echo "$ZKSYNC_ESCROW_CONTRACT_ADDRESS\n"

BALANCE_USER_L2_BEFORE_SETORDER=$(cast balance --rpc-url http://localhost:3050 $USER_ZKSYNC_PUBLIC_ADDRESS)
echo "Initial User funds: $BALANCE_USER_L2_BEFORE_SETORDER"

BALANCE_ESCROW_L2_BEFORE_SETORDER=$(cast balance --rpc-url http://localhost:3050 $ZKSYNC_ESCROW_CONTRACT_ADDRESS)
echo "Initial Escrow funds: $BALANCE_ESCROW_L2_BEFORE_SETORDER"

npx zksync-cli contract write --private-key $USER_ZKSYNC_PRIVATE_ADDRESS --rpc http://localhost:3050 --contract "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" --method "set_order(address recipient_address, uint256 fee)" --args "$USER_ETHEREUM_PUBLIC_ADDRESS" "$FEE" --value "$VALUE" >> /dev/null

BALANCE_USER_L2_AFTER_SETORDER=$(cast balance --rpc-url http://localhost:3050 $USER_ZKSYNC_PUBLIC_ADDRESS)
echo "Final User funds: $BALANCE_USER_L2_AFTER_SETORDER"


BALANCE_ESCROW_L2_AFTER_SETORDER_WEI=$(cast balance --rpc-url http://localhost:3050 $ZKSYNC_ESCROW_CONTRACT_ADDRESS) #for assert.sh
BALANCE_ESCROW_L2_AFTER_SETORDER=$(cast balance --rpc-url http://localhost:3050 $ZKSYNC_ESCROW_CONTRACT_ADDRESS) #for logging
echo "Final Escrow funds:$BALANCE_ESCROW_L2_AFTER_SETORDER"
