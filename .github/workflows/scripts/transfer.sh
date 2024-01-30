#!/bin/bash

amount=124000000000000
eth_contract=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

echo -e "${GREEN}\n=> [SN] Making transfer to Destination account${COLOR_RESET}" # 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 -> 642829559307850963015472508762062935916233390536

echo "Initial balance:"
cast balance --rpc-url $ETH_RPC_URL --ether 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
echo "Transferring $amount to 0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
cast send --rpc-url $ETH_RPC_URL --private-key $ETH_PRIVATE_KEY $eth_contract "transfer(uint256, uint256, uint256)" "0" "642829559307850963015472508762062935916233390536" "$amount" --value $amount
echo "Final balance:"
cast balance --rpc-url $ETH_RPC_URL --ether 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
