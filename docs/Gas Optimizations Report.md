# Report about optimizations made on PaymentRegistry:

## Applied optimizations on PaymentRegistry:

- Removed unnecesarry Events

- Removed unnecesarry "amount" param in transfer()
- Removed unnecesarry "require(dest.address != 0)" in transfer()
- Changed ">" to ">=" because its cheaper
- Changed error messages length
- Optimized size of payload sent to L2 (from 5 u256 to 3 u256)
    - This needed a change in SN Escrow.cairo as well

## Also some other cases where studied but not applied:
- Can't shrink "u256 destAddress" size, since SN address is u256

- Can't shirnk "u256 amount" size since amount=msg.value, and msg.value is u256
- struct TransferInfo is an expensive one but has all necesarry info
- Changing orderId from u256 to u32 is more expensive, could not figure out why
    - My theory is because EVM takes more time finding a small memory slot of u32
    - This change trying reordering variables could yield better results
- Recieving _snEscrowClaimPaymentSelector from init() parameter is cheaper than:
    - hardcoding value in memory
    - hardcoding value in init
- The following call in transfer() is very expensive so i tried to optimize it:
    - payable(addr).call{value}
        - vs payable(addr).send(value)
        - vs payabale(addr).transfer(value)
            - changing to either send or transfer is cheaper, but it is not recommended by the community due to possible re-entrancy attacks
        - vs payable(addr).call{value, gasFee}
            - limiting the gasFee makes the execution cheaper, and/but limits the posibility of this call executing something else

## Gas reports:
Following, we have gas reporst, generated with

```bash
forge test --gas-report
```

Note the most important variables here are **Deployment Cost**, which affects the cost of deploying our contracts, and the execution of functions **transfer()** and **claimPayment()**, which affect the user in the the cost of the bridge.

### Pre-optimiziations Report:

| ERC1967Proxy contract |                 |        |        |        |         |
|----------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                  | Deployment Size |        |        |        |         |
| 130457                                                                                                                           | 1130            |        |        |        |         |
| Function Name                                                                                                                    | min             | avg    | median | max    | # calls |
| claimPayment                                                                                                                     | 31211           | 42598  | 45931  | 52631  | 6       |
| getMMAddress                                                                                                                     | 765             | 4015   | 4015   | 7265   | 2       |
| initialize                                                                                                                       | 144784          | 144784 | 144784 | 144784 | 12      |
| owner                                                                                                                            | 7325            | 7325   | 7325   | 7325   | 1       |
| setMMAddress                                                                                                                     | 28990           | 31490  | 31490  | 33991  | 2       |
| transfer                                                                                                                         | 31168           | 118292 | 135643 | 136015 | 6       |


| PaymentRegistry contract |                 |        |        |        |         |
|--------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                  | Deployment Size |        |        |        |         |
| 1155326                                          | 5236            |        |        |        |         |
| Function Name                                    | min             | avg    | median | max    | # calls |
| claimPayment                                     | 4809            | 16147  | 19548  | 26248  | 6       |
| getMMAddress                                     | 375             | 1375   | 1375   | 2375   | 2       |
| initialize                                       | 117439          | 117439 | 117439 | 117439 | 12      |
| owner                                            | 2435            | 2435   | 2435   | 2435   | 1       |
| setMMAddress                                     | 2661            | 5165   | 5165   | 7669   | 2       |
| transfer                                         | 4766            | 91844  | 109260 | 109260 | 6       |




### Post-optimizations Report

| ERC1967Proxy contract |                 |        |        |        |         |
|----------------------------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                                                                  | Deployment Size |        |        |        |         |
| 130457                                                                                                                           | 1130            |        |        |        |         |
| Function Name                                                                                                                    | min             | avg    | median | max    | # calls |
| claimPayment                                                                                                                     | 31166           | 42326  | 45534  | 52234  | 6       |
| getMMAddress                                                                                                                     | 765             | 4015   | 4015   | 7265   | 2       |
| initialize                                                                                                                       | 144784          | 144784 | 144784 | 144784 | 12      |
| owner                                                                                                                            | 7259            | 7259   | 7259   | 7259   | 1       |
| setMMAddress                                                                                                                     | 28990           | 31490  | 31490  | 33991  | 2       |
| transfer                                                                                                                         | 30947           | 117903 | 135295 | 135295 | 6       |


| PaymentRegistry contract |                 |        |        |        |         |
|--------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                  | Deployment Size |        |        |        |         |
| 1025205                                          | 4634            |        |        |        |         |
| Function Name                                    | min             | avg    | median | max    | # calls |
| claimPayment                                     | 4770            | 15876  | 19151  | 25851  | 6       |
| getMMAddress                                     | 375             | 1375   | 1375   | 2375   | 2       |
| initialize                                       | 117439          | 117439 | 117439 | 117439 | 12      |
| owner                                            | 2369            | 2369   | 2369   | 2369   | 1       |
| setMMAddress                                     | 2661            | 5165   | 5165   | 7669   | 2       |
| transfer                                         | 4694            | 91664  | 109058 | 109058 | 6       |


## Conclusions

The following Gas consumptions have decreased:
- 113 thousand gas in deploy (13%)
- 400 gas in claimPayment() (2%)
- 200 gas in transfer() (0.2%)

Since there was no significant change made on the bridge operations in the user's perspective, my recommendation is to keep on learning more on gas optimization techniques; and keep on trying to lower these consumptions, primarily the execution of functions claimPayment() and transfer().

 