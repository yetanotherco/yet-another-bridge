#!/bin/bash
# cast call 0x97589bcE7727f5D0C8082440681DB6092b6Dda1a "getNames()(string)" --rpc-url http://localhost:8545
# exit

. contracts/utils/colors.sh #for ANSI colors

FEE=10000000000000000 #in WEI
VALUE=2 #in ETH
VALUE_WEI=$(echo "scale=0; $VALUE * 10^18" | bc)
BRIDGE_AMOUNT_WEI=$(echo "scale=0; $VALUE_WEI - $FEE" | bc)
BRIDGE_AMOUNT_ETH=$(echo "scale=18; $BRIDGE_AMOUNT_WEI / 10^18" | bc)
# BRIDGE_AMOUNT_WEI=$(printf "%.0f" "$BRIDGE_AMOUNT_WEI")


printf "${GREEN}\n=> [SN] Making Set Order on Escrow${COLOR_RESET}\n"
echo "\nUser ZKSync funds before setOrder:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$USER_ZKSYNC_PUBLIC_ADDRESS" | grep -E -o "\d+(\.\d+)? ETH"
echo "\nEscrow ZKSync funds before setOrder:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" | grep -E -o "\d+(\.\d+)? ETH"


npx zksync-cli contract write --private-key $USER_ZKSYNC_PRIVATE_ADDRESS --chain "dockerized-node" --contract "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" --method "set_order(address recipient_address, uint256 fee)" --args "$USER_ETHEREUM_PUBLIC_ADDRESS" "$FEE" --value "$VALUE" >> /dev/null


echo "\nUser ZKSync funds after setOrder:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$USER_ZKSYNC_PUBLIC_ADDRESS" | grep -E -o "\d+(\.\d+)? ETH"
echo "\nEscrow ZKSync funds after setOrder:"
npx zksync-cli wallet balance --chain "dockerized-node" --address "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" | grep -E -o "\d+(\.\d+)? ETH"
