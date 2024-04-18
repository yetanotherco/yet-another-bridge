import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract, Fragment, Wallet, Provider } from 'ethers';
import { getWallet, deployContract, LOCAL_RICH_WALLETS, getProvider } from '../deploy/utils';

let provider: Provider;
let escrow: Contract;
let paymentRegistry: Wallet = getWallet(LOCAL_RICH_WALLETS[3].privateKey); //its Wallet data type because I will mock calls from this addr

let deployer: Wallet = getWallet(LOCAL_RICH_WALLETS[0].privateKey);
let user_zk: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_zk2: Wallet = getWallet(LOCAL_RICH_WALLETS[2].privateKey);
let user_eth: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_eth2: Wallet = getWallet(LOCAL_RICH_WALLETS[2].privateKey);



const fee = 1; //TODO check, maybe make fuzz
const value = 10; //TODO check, maybe make fuzz

beforeEach( async () => {
  escrow = await deployAndInit();
  // erc20 = await deployContract("ERC20", deployer, [1000]);
  provider = getProvider();
});



describe('ERC20 Set Order tests', function () {
  // it("Should emit correct Event", async () => {
  //   const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth, fee, {value});

  //   await expect(setOrderTx)
  //     .to.emit(escrow, "SetOrder").withArgs(0, user_eth, value-fee, fee)
  // });
  // it("Should get the order setted", async () => {
  //   const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});

  //   await expect(setOrderTx)
  //     .to.emit(escrow, "SetOrder").withArgs(0, user_eth, value-fee, fee)

  //   const newOrder = await escrow.get_order(0);

  //   expect(newOrder[0]).to.eq(user_eth.address); //recipient_address
  //   expect(Number(newOrder[1])).to.eq(value-fee); //amount
  //   expect(Number(newOrder[2])).to.eq(fee); //fee
  // })
  // it("Should get the pending order", async () => {
  //   const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
  //   await setOrderTx.wait();

  //   expect(await escrow.is_order_pending(0)).to.equal(true);
  // })
  // it("Should not get the pending order", async () => {
  //   expect(await escrow.is_order_pending(0)).to.equal(false);
  // })
});

describe('ERC20 Claim Payment tests', function () {
  // it("Should allow PaymentRegistry to claim payment", async () => {
  //   let mm_init_balance = await provider.getBalance(escrow.mm_zksync_wallet());
    
  //   const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
  //   await setOrderTx.wait();

  //   const claimPaymentTx = await escrow.connect(paymentRegistry).claim_payment(0, user_eth, value-fee);
  //   await claimPaymentTx.wait();

  //   let mm_final_balance = await provider.getBalance(escrow.mm_zksync_wallet());

  //   expect(mm_final_balance - mm_init_balance).to.equals(value);
  // });

  // it("Should not allow PaymentRegistry to claim unexisting payment", async () => {
  //   expect(escrow.connect(paymentRegistry).claim_payment(0, user_eth, value-fee)).to.be.revertedWith("Order claimed or nonexistent");
  // });

  // it("Should not allow random user to call claim payment", async () => {
  //   expect(escrow.connect(user_zk).claim_payment(0, user_eth, value)).to.be.revertedWith("Only PAYMENT_REGISTRY can call");
  // });
})

