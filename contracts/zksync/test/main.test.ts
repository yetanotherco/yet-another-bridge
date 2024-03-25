import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract, Fragment, Wallet } from 'ethers';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';

let escrow: Contract;
let deployer: Wallet = getWallet(LOCAL_RICH_WALLETS[0].privateKey);
let user_zk: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_zk2: Wallet = getWallet(LOCAL_RICH_WALLETS[2].privateKey);
let user_eth: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_eth2: Wallet = getWallet(LOCAL_RICH_WALLETS[2].privateKey);


const fee = 1; //TODO check, maybe make fuzz
const value = 10; //TODO check, maybe make fuzz

beforeEach( async () => {
  escrow = await deployAndInit();
});

// /*
// working:::
// describe('Pause tests', function () {

//   it("Should start unpaused", async function () {
//     expect(await escrow.paused()).to.eq(false);
//   });

//   it("Should pause", async function ()  {
//     const setPauseTx = await escrow.pause();
//     await setPauseTx.wait();

//     expect(await escrow.paused()).to.equal(true);
//   });

//   it("Should unpause", async function ()  {
//     const setPauseTx = await escrow.pause();
//     await setPauseTx.wait();

//     const setUnpauseTx = await escrow.unpause();
//     await setUnpauseTx.wait();

//     expect(await escrow.paused()).to.eq(false);
//   });
  
//   it("Should not allow when paused: set_mm_zksync_wallet", async () => {
//     const setPauseTx = await escrow.pause();
//     await setPauseTx.wait();
//     await expect(escrow.set_mm_zksync_wallet(user_zk)).to.be.revertedWith("Pausable: paused");
//   });

//   it("Should not allow when paused: set_ethereum_payment_registry", async () => {
//     const setPauseTx = await escrow.pause();
//     await setPauseTx.wait();
//     await expect(escrow.set_ethereum_payment_registry(user_eth)).to.be.revertedWith("Pausable: paused");
//   });

//   it("Should not allow when paused: set_order", async () => {
//     const setPauseTx = await escrow.pause();
//     await setPauseTx.wait();
//     await expect(escrow.set_order(user_eth, fee, {value})).to.be.revertedWith("Pausable: paused");
//   });
  
// });
// // */
// // // working ::
// describe('Set Order tests', function () {
//   it("Should emit correct Event", async () => {
//     let events = await escrow.queryFilter("*");
//     const events_length = events.length;

//     const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
//     await setOrderTx.wait();
    
//     events = await escrow.queryFilter("*");
//     expect(events.length).to.equal(events_length + 1);
//     expect(events[events.length - 1].fragment.name).to.equal("SetOrder");
//   });

//   it("Should get the order setted", async () => {
//     const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
//     await setOrderTx.wait();

//     let events = await escrow.queryFilter("*");
//     const newOrderEvent = events[events.length - 1];

//     const orderId = newOrderEvent.args[0];

//     const newOrder = await escrow.get_order(orderId);

//     expect(newOrder[0]).to.eq(user_eth.address); //recipient_address
//     expect(Number(newOrder[1])).to.eq(value-fee); //amount
//     expect(Number(newOrder[2])).to.eq(fee); //fee
//   })

//   it("Should get the pending order", async () => {
//     const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
//     await setOrderTx.wait();

//     expect(await escrow.is_order_pending(0)).to.equal(true);
//   })
//   it("Should not get the pending order", async () => {
//     expect(await escrow.is_order_pending(0)).to.equal(false);
//   })
// })

// describe('Ownable tests', function () {
//   it("Should not allow random user to pause", async () => {
//     await expect(escrow.connect(user_zk).pause()).to.be.revertedWith("Ownable: caller is not the owner");
//   });

//   it("Should not allow random user to unpause", async () => {
//     const setPauseTx = await escrow.pause();
//     await setPauseTx.wait();
//     await expect(escrow.connect(user_zk).unpause()).to.be.revertedWith("Ownable: caller is not the owner");
//   });

//   it("Should not allow random user to set_mm_zksync_wallet", async () => {
//     await expect(escrow.connect(user_zk).set_mm_zksync_wallet(user_zk)).to.be.revertedWith("Ownable: caller is not the owner");
//   });

//   it("Should allow owner to set_mm_zksync_wallet", async () => {
//     const setTx = await escrow.set_mm_zksync_wallet(user_zk2);
//     await setTx.wait();

//     expect(await escrow.mm_zksync_wallet()).to.equals(user_zk2.address);
//   });

//   it("Should not allow random user to set_ethereum_payment_registry", async () => {
//     await expect(escrow.connect(user_zk).set_ethereum_payment_registry(user_eth)).to.be.revertedWith("Ownable: caller is not the owner");
//   });

//   it("Should allow owner to set_ethereum_payment_registry", async () => {
//     const setTx = await escrow.set_ethereum_payment_registry(user_eth2);
//     await setTx.wait();

//     expect(await escrow.ethereum_payment_registry()).to.equals(user_eth2.address);
//   });

// })

describe('Claim payment batch tests', function () { 
  // it("Should emit correct Event", async () => {
  //   const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
  //   await setOrderTx.wait();

  //   const claimPaymentBatchTx = await escrow.connect(user_eth).claim_payment_batch([0]);
  //   await claimPaymentBatchTx.wait();

  //   let events = await escrow.queryFilter("ClaimPaymentBatch", "latest");
  //   const newClaimPaymentBatchEvent = events[events.length - 1];

  //   expect(newClaimPaymentBatchEvent.args[0].length).to.equal(1);
  // });

  it("Should claim payment batch", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    const claimPaymentBatchTx = await escrow.connect(user_eth).claim_payment_batch([0], [user_eth.address], [value-fee])
    await claimPaymentBatchTx.wait();

    expect(await escrow.is_order_pending(0)).to.equal(false);
  });

  // it("Should not claim payment batch", async () => {
  //   await expect(escrow.connect(user_eth).claim_payment_batch([0])).to.be.revertedWith("Escrow: order not pending");
  // });
});

