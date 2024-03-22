printf "${GREEN}\n=> Newly deployed contracts information: ${COLOR_RESET}\n"
printf "${PINK}[ETH] Deployed Proxy of PaymentRegistry address: $PAYMENT_REGISTRY_PROXY_ADDRESS ${COLOR_RESET}\n"

if ! [ -z "$ESCROW_CONTRACT_ADDRESS" ]; then
    printf "${CYAN}[SN] Escrow Address: $ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"
fi
if ! [ -z "$ZKSYNC_ESCROW_CONTRACT_ADDRESS" ]; then
    printf "${CYAN}[ZKSync] Escrow Address: $ZKSYNC_ESCROW_CONTRACT_ADDRESS${COLOR_RESET}\n"
fi
