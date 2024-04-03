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

// let mm: Wallet = getWallet(LOCAL_RICH_WALLETS[4].privateKey);


const fee = 1; //TODO check, maybe make fuzz
const value = 10; //TODO check, maybe make fuzz

beforeEach( async () => {
  escrow = await deployAndInit();
  provider = getProvider();
});


describe('Pause tests', function () {
  it("Should start unpaused", async function () {
    expect(await escrow.paused()).to.eq(false);
  });

  it("Should pause", async function ()  {
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();

    expect(await escrow.paused()).to.equal(true);
  });

  it("Should unpause", async function ()  {
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();

    const setUnpauseTx = await escrow.unpause();
    await setUnpauseTx.wait();

    expect(await escrow.paused()).to.eq(false);
  });
  
  it("Should not allow when paused: set_mm_zksync_wallet", async () => {
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();
    await expect(escrow.set_mm_zksync_wallet(user_zk)).to.be.revertedWith("Pausable: paused");
  });

  it("Should not allow when paused: set_ethereum_payment_registry", async () => {
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();
    await expect(escrow.set_ethereum_payment_registry(user_eth)).to.be.revertedWith("Pausable: paused");
  });

  it("Should not allow when paused: set_order", async () => {
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();
    await expect(escrow.set_order(user_eth, fee, {value})).to.be.revertedWith("Pausable: paused");
  });

  it("Should not allow when paused: claim_payment", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();

    await expect(escrow.claim_payment(0, user_eth, value-fee)).to.be.revertedWith("Pausable: paused");
  });
  
});

describe('Set Order tests', function () {
  it("Should emit correct Event", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});

    await expect(setOrderTx)
      .to.emit(escrow, "SetOrder").withArgs(0, user_eth, value-fee, fee)
  });

  it("Should get the order setted", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});

    await expect(setOrderTx)
      .to.emit(escrow, "SetOrder").withArgs(0, user_eth, value-fee, fee)

    const newOrder = await escrow.get_order(0);

    expect(newOrder[0]).to.eq(user_eth.address); //recipient_address
    expect(Number(newOrder[1])).to.eq(value-fee); //amount
    expect(Number(newOrder[2])).to.eq(fee); //fee
  })

  it("Should get the pending order", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    expect(await escrow.is_order_pending(0)).to.equal(true);
  })
  it("Should not get the pending order", async () => {
    expect(await escrow.is_order_pending(0)).to.equal(false);
  })
})


describe('Claim Payment tests', function () {
  it("Should allow PaymentRegistry to claim payment", async () => {
    let mm_init_balance = await provider.getBalance(escrow.mm_zksync_wallet());
    
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    const claimPaymentTx = await escrow.connect(paymentRegistry).claim_payment(0, user_eth, value-fee);
    await claimPaymentTx.wait();

    let mm_final_balance = await provider.getBalance(escrow.mm_zksync_wallet());

    expect(mm_final_balance - mm_init_balance).to.equals(value);
  });

  it("Should not allow PaymentRegistry to claim unexisting payment", async () => {
    expect(escrow.connect(paymentRegistry).claim_payment(0, user_eth, value-fee)).to.be.revertedWith("Order claimed or nonexistent");
  });

  it("Should not allow random user to call claim payment", async () => {
    expect(escrow.connect(user_zk).claim_payment(0, user_eth, value)).to.be.revertedWith("Only PAYMENT_REGISTRY can call");
  });
})



describe('Ownable tests', function () {
  it("Should not allow random user to pause", async () => {
    await expect(escrow.connect(user_zk).pause()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not allow random user to unpause", async () => {
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();
    await expect(escrow.connect(user_zk).unpause()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not allow random user to set_mm_zksync_wallet", async () => {
    await expect(escrow.connect(user_zk).set_mm_zksync_wallet(user_zk)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should allow owner to set_mm_zksync_wallet", async () => {
    const setTx = await escrow.set_mm_zksync_wallet(user_zk2);
    await setTx.wait();

    expect(await escrow.mm_zksync_wallet()).to.equals(user_zk2.address);
  });

  it("Should not allow random user to set_ethereum_payment_registry", async () => {
    await expect(escrow.connect(user_zk).set_ethereum_payment_registry(user_eth)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should allow owner to set_ethereum_payment_registry", async () => {
    const setTx = await escrow.set_ethereum_payment_registry(user_eth2);
    await setTx.wait();

    expect(await escrow.ethereum_payment_registry()).to.equals(user_eth2.address);
  });

})

describe('Claim payment batch tests', function () { 
  
  it("Should claim payment batch", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    const setOrderTx2 = await escrow.connect(user_zk2).set_order(user_eth2, fee, {value});
    await setOrderTx2.wait();

    await escrow.connect(deployer).set_ethereum_payment_registry(user_eth);
    await escrow.connect(deployer).set_mm_zksync_wallet(user_zk);

    const tx = await escrow.connect(user_eth).claim_payment_batch([0, 1], [user_eth.address, user_eth2.address], [value-fee, value-fee]);

    await expect(tx)
      .to.emit(escrow, "ClaimPayment").withArgs(0, user_zk.address, value-fee)
      .to.emit(escrow, "ClaimPayment").withArgs(1, user_zk.address, value-fee);

    expect(await escrow.is_order_pending(0)).to.equal(false);
  });

  it("Should not claim payment batch when order missing", async () => {
    await escrow.connect(deployer).set_ethereum_payment_registry(user_eth);

    await expect(escrow.connect(user_eth).claim_payment_batch([0], [user_eth.address], [value-fee])).to.be.revertedWith("Order claimed or nonexistent");
  });

  it("Should not claim payment batch when not PAYMENT_REGISTRY", async () => {
    const setOrderTx = await escrow.connect(user_zk).set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    await expect(escrow.connect(user_eth).claim_payment_batch([0], [user_eth.address], [value-fee])).to.be.revertedWith("Only PAYMENT_REGISTRY can call");
  });
});

