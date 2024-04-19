import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract, Fragment, Wallet, Provider, AddressLike } from 'ethers';
import { getWallet, deployContract, LOCAL_RICH_WALLETS, getProvider } from '../deploy/utils';

let provider: Provider;
let escrow: Contract;
let erc20_l2: Contract;
let erc20_l1: Contract;
let paymentRegistry: Wallet = getWallet(LOCAL_RICH_WALLETS[3].privateKey); //its Wallet data type because I will mock calls from this addr

let deployer: Wallet = getWallet(LOCAL_RICH_WALLETS[0].privateKey);
let user_zk: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_zk2: Wallet = getWallet(LOCAL_RICH_WALLETS[2].privateKey);
let user_eth: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_eth2: Wallet = getWallet(LOCAL_RICH_WALLETS[2].privateKey);



const fee = 1; //TODO check, maybe make fuzz
const value = 10; //TODO check, maybe make fuzz
const amount_l2 = 20;
const amount_l1 = 10;

const erc20_l1_address = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
let erc20_l2_address: AddressLike;
let escrow_address: AddressLike;

const initial_erc20_balance = 1000000;

beforeEach( async () => {
  escrow = await deployAndInit();
  escrow_address = await escrow.getAddress();

  erc20_l2 = await deployContract("UriCoin", [user_zk.address, initial_erc20_balance], { wallet: deployer });
  erc20_l2_address = await erc20_l2.getAddress();
  
  provider = getProvider();
});


describe('ERC20 basic tests', function () {
  it("Should airdrop correctly", async () => {
    const balanceOf = await erc20_l2.balanceOf(user_zk.address);
    expect(balanceOf).to.eq(initial_erc20_balance)
  });

  it("Should transfer correctly", async () => {
    const transferTx = await erc20_l2.connect(user_zk).transfer(user_zk2.address, value);
    await transferTx.wait();

    const balanceOf = await erc20_l2.balanceOf(user_zk2.address);
    expect(balanceOf).to.eq(value)
  });

  it("Should not transfer more than balance", async () => {
    expect(erc20_l2.connect(user_zk).transfer(user_zk2.address, initial_erc20_balance+1)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
  });

  it("Should not transfer without allowance", async () => {
    expect(erc20_l2.connect(user_zk2).transferFrom(user_zk.address, user_zk2.address, value)).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
  });

  it("Should approve correctly", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(user_zk2.address, value);
    await approveTx.wait();

    const allowance = await erc20_l2.allowance(user_zk.address, user_zk2.address);
    expect(allowance).to.eq(value)
  });

  it("Should transferFrom correctly", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(user_zk2.address, value);
    await approveTx.wait();

    const transferFromTx = await erc20_l2.connect(user_zk2).transferFrom(user_zk.address, user_zk2.address, value);
    await transferFromTx.wait();

    const balanceOf = await erc20_l2.balanceOf(user_zk2.address);
    expect(balanceOf).to.eq(value)
  });
})


describe('ERC20 Set Order tests', function () {
  it("Should emit correct Event", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(escrow_address, amount_l2);
    await approveTx.wait();

    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, erc20_l2_address, erc20_l1_address, {value: fee});

    await expect(setOrderTx)
      .to.emit(escrow, "SetOrderERC20").withArgs(0, user_eth.address, amount_l2, amount_l1, fee, erc20_l2_address, erc20_l1_address);
  });
  it("Should get the order setted", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(escrow_address, amount_l2);
    await approveTx.wait();

    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, erc20_l2_address, erc20_l1_address, {value: fee});
    await setOrderTx.wait();

    const newOrder = await escrow.get_order_erc20(0);

    expect(newOrder[0]).to.eq(user_eth.address); //recipient_address
    expect(Number(newOrder[1])).to.eq(amount_l2); //amount_l2
    expect(Number(newOrder[2])).to.eq(amount_l1); //amount_l1
    expect(Number(newOrder[3])).to.eq(fee); //fee
    expect(newOrder[4]).to.eq(erc20_l2_address); //erc20_l2_address
    expect(newOrder[5]).to.eq(erc20_l1_address); //erc20_l1_address
  })
  it("Should get the pending order", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(escrow_address, amount_l2);
    await approveTx.wait();

    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, erc20_l2_address, erc20_l1_address, {value: fee});
    await setOrderTx.wait();

    expect(await escrow.is_order_pending(0)).to.equal(true);
  })
  it("Should not get the pending order", async () => {
    expect(await escrow.is_order_pending(0)).to.equal(false);
  })
});

describe('ERC20 Claim Payment tests', function () {
  it("Should allow PaymentRegistry to claim payment", async () => {
    let mm_init_balance = await erc20_l2.balanceOf(escrow.mm_zksync_wallet());
    
    const approveTx = await erc20_l2.connect(user_zk).approve(escrow_address, amount_l2);
    await approveTx.wait();

    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, erc20_l2_address, erc20_l1_address, {value: fee});
    await setOrderTx.wait();

    //claims the payment of a transfer of amount_l1 made to erc20_l1
    const claimPaymentTx = await escrow.connect(paymentRegistry).claim_payment_erc20(0, user_eth, amount_l1, erc20_l1_address); //unit testing the Escrow, not the PaymentRegistry's transfer/claim_payment ACL
    await claimPaymentTx.wait();

    let mm_final_balance = await erc20_l2.balanceOf(escrow.mm_zksync_wallet());

    //MM balance should increase by amount_l2
    expect(mm_final_balance - mm_init_balance).to.equals(amount_l2);
  });

  it("Should not allow PaymentRegistry to claim unexisting payment", async () => {
    expect(escrow.connect(paymentRegistry).claim_payment_erc20(0, user_eth, amount_l1, erc20_l1_address)).to.be.revertedWith("Order claimed or nonexistent");
  });

  it("Should not allow random user to call claim payment", async () => {
    expect(escrow.connect(user_zk).claim_payment_erc20(0, user_eth, amount_l1, erc20_l1_address)).to.be.revertedWith("Only PAYMENT_REGISTRY can call");
  });

  it("Should not allow PaymentRegistry to claim claimed payment", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(escrow_address, amount_l2);
    await approveTx.wait();

    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, erc20_l2_address, erc20_l1_address, {value: fee});
    await setOrderTx.wait();

    //claims the payment of a transfer of amount_l1 made to erc20_l1
    const claimPaymentTx = await escrow.connect(paymentRegistry).claim_payment_erc20(0, user_eth, amount_l1, erc20_l1_address); //unit testing the Escrow, not the PaymentRegistry's transfer/claim_payment ACL
    await claimPaymentTx.wait();

    expect(escrow.connect(user_zk).claim_payment_erc20(0, user_eth, amount_l1, erc20_l1_address)).to.be.revertedWith("Only PAYMENT_REGISTRY can call");
  });
  it("Should not get the pending order after being claimed", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(escrow_address, amount_l2);
    await approveTx.wait();

    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, erc20_l2_address, erc20_l1_address, {value: fee});
    await setOrderTx.wait();

    //claims the payment of a transfer of amount_l1 made to erc20_l1
    const claimPaymentTx = await escrow.connect(paymentRegistry).claim_payment_erc20(0, user_eth, amount_l1, erc20_l1_address); //unit testing the Escrow, not the PaymentRegistry's transfer/claim_payment ACL
    await claimPaymentTx.wait();

    expect(await escrow.is_order_pending(0)).to.equal(false);  
  });
})

