#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

source .github/workflows/katana/katana.env
set -e

export STARKNET_ACCOUNT=$ACCOUNT_SRC
export STARKNET_RPC=$RPC_URL

# Check if the JSON file exists
if [ ! -f "$ACCOUNT_SRC" ]; then
    $(starkli account fetch --output $ACCOUNT_SRC $ACCOUNT_ADDRESS)
    echo -e "$GREEN\n==> Katana JSON account file created at: $ACCOUNT_SRC$RESET"
else
    echo -e "$GREEN\n==> Katana JSON account file already exists at: $ACCOUNT_SRC$RESET"
fi
