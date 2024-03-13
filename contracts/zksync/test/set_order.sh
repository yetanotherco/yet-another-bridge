#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

FEE=1000000000000000 #in WEI
VALUE=0.1 #in ETH

RECIPIENT_ADDRESS=0xceee57f2b700c2f37d1476a7974965e149fce2d4 #L1 wallet with no funds

echo -e "${GREEN}\n=> [SN] Making Set Order on Escrow${COLOR_RESET}"

export 
npx zksync-cli contract write --private-key $WALLET_PRIVATE_KEY --chain "dockerized-node" --contract "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" --method "set_order(address recipient_address, uint256 fee)" --args "$RECIPIENT_ADDRESS" "$FEE" --value "$VALUE"
