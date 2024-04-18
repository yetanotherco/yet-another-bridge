import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract, Fragment, Wallet, Provider } from 'ethers';
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
let erc20_l2_address: string;

const initial_erc20_balance = 1000000;

beforeEach( async () => {
  escrow = await deployAndInit();
  erc20_l2 = await deployContract("UriCoin", [user_zk.address, initial_erc20_balance], { wallet: deployer });
  erc20_l2_address = await erc20_l2.getAddress();
  
  provider = getProvider();
});

//working:
// describe('ERC20 basic tests', function () {
//   it("Should airdrop correctly", async () => {
//     const balanceOf = await erc20.balanceOf(user_zk.address);
//     expect(balanceOf).to.eq(initial_erc20_balance)
//   });

//   it("Should transfer correctly", async () => {
//     const transferTx = await erc20.connect(user_zk).transfer(user_zk2.address, value);
//     await transferTx.wait();

//     const balanceOf = await erc20.balanceOf(user_zk2.address);
//     expect(balanceOf).to.eq(value)
//   });

//   it("Should not transfer more than balance", async () => {
//     expect(erc20.connect(user_zk).transfer(user_zk2.address, initial_erc20_balance+1)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
//   });

//   it("Should not transfer without allowance", async () => {
//     expect(erc20.connect(user_zk2).transferFrom(user_zk.address, user_zk2.address, value)).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
//   });

//   it("Should approve correctly", async () => {
//     const approveTx = await erc20.connect(user_zk).approve(user_zk2.address, value);
//     await approveTx.wait();

//     const allowance = await erc20.allowance(user_zk.address, user_zk2.address);
//     expect(allowance).to.eq(value)
//   });

//   it("Should transferFrom correctly", async () => {
//     const approveTx = await erc20.connect(user_zk).approve(user_zk2.address, value);
//     await approveTx.wait();

//     const transferFromTx = await erc20.connect(user_zk2).transferFrom(user_zk.address, user_zk2.address, value);
//     await transferFromTx.wait();

//     const balanceOf = await erc20.balanceOf(user_zk2.address);
//     expect(balanceOf).to.eq(value)
//   });
// })


describe('ERC20 Set Order tests', function () {
  it("Should emit correct Event", async () => {
    const approveTx = await erc20_l2.connect(user_zk).approve(await erc20_l2.getAddress(), amount_l2);
    await approveTx.wait();

    const allowance = await erc20_l2.allowance(user_zk.address, await erc20_l2.getAddress());
    expect(allowance).to.eq(amount_l2)

    //contract caller is not being correctly set.
    const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth.address, amount_l2, amount_l1, await erc20_l2.getAddress(), erc20_l1_address, {value: fee});

    await expect(setOrderTx)
      .to.emit(escrow, "SetOrder").withArgs(0, user_eth.address, amount_l2, amount_l1, fee, erc20_l2_address, erc20_l1_address);
  });
  // it("Should emit correct Event", async () => {
  //   const setOrderTx = await escrow.connect(user_zk).set_order_erc20(user_eth, fee, {value});

  //   await expect(setOrderTx)
  //     .to.emit(escrow, "SetOrder").withArgs(0, user_eth, value-fee, fee);
  // });
  // it("Should get the order setted", async () => {
  //   const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});

  //   await expect(setOrderTx)
  //     .to.emit(escrow, "SetOrder").withArgs(0, user_eth, value-fee, fee);

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

