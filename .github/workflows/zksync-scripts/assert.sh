#!/bin/bash

. contracts/utils/colors.sh #for ANSI colors

echo "Asserting values"
FAILED=false

assert() {
  #Usage: assert <variable_name> <obtained> <expected>
  if [ $2 = $3 ] ; then
    printf "${GREEN}✓ $1 passed.${RESET}\n"
  else
    printf "${RED}x $1 assertion failed: Obtained value: $2, Expected value: $3.${RESET}\n"
    FAILED=true
  fi
}

assert "Escrow balance after SetOrder" $BALANCE_ESCROW_L2_AFTER_SETORDER_WEI $VALUE_WEI #2000000000000000000
assert "Escrow balance after Claim Payment" $BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT_WEI 0

# assert BALANCE_USER_L1_BEFORE_TRANSFER $BALANCE_USER_L1_BEFORE_TRANSFER 0
assert "User balance" $BALANCE_USER_L1_AFTER_TRANSFER_WEI $BRIDGE_AMOUNT_WEI #1990000000000000000

assert "MM balance" $(($BALANCE_MM_L2_AFTER_CLAIMPAYMENT_WEI)) $(($BALANCE_MM_L2_BEFORE_CLAIMPAYMENT_WEI + $VALUE_WEI))

if $FAILED; then
  echo "One of the previous tests failed, all should pass for Integration Test to be successful"
  exit 1
fi
exit 0
