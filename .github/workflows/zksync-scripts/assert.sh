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

#solo hace falta validar:
echo "solo hace falta validar:"

assert BALANCE_ESCROW_L2_AFTER_SETORDER $BALANCE_ESCROW_L2_AFTER_SETORDER $VALUE_WEI #2000000000000000000
assert BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT $BALANCE_ESCROW_L2_AFTER_CLAIMPAYMENT 0

assert BALANCE_USER_L1_BEFORE_TRANSFER $BALANCE_USER_L1_BEFORE_TRANSFER 0
assert BALANCE_USER_L1_AFTER_TRANSFER $BALANCE_USER_L1_AFTER_TRANSFER $BRIDGE_AMOUNT_WEI #1990000000000000000

assert BALANCE_MM_L2_AFTER_CLAIMPAYMENT $(($BALANCE_MM_L2_AFTER_CLAIMPAYMENT)) $(($BALANCE_MM_L2_BEFORE_CLAIMPAYMENT + $VALUE_WEI)) #/100 because it has overflow

if $FAILED; then
  echo A test failed
  exit 1
fi
exit 0