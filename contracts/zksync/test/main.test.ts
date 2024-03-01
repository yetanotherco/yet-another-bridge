import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract, Fragment, Wallet } from 'ethers';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';

let escrow: Contract;
let deployer: Wallet = getWallet(LOCAL_RICH_WALLETS[0].privateKey);
let user_zk: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_eth: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);

const fee = 1; //TODO check, maybe make fuzz
const value = 10; //TODO check, maybe make fuzz

beforeEach( async () => {
  escrow = await deployAndInit();
});

// working:::
describe('Pause tests', function () {

  it("Should start unpaused", async function () {
    expect(await escrow.paused()).to.eq(false);
  });

  it("Should pause", async function ()  {
    escrow.connect(deployer);
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();

    expect(await escrow.paused()).to.equal(true);
  });

  it("Should unpause", async function ()  {
    escrow.connect(deployer);
    const setPauseTx = await escrow.pause();
    await setPauseTx.wait();

    const setUnpauseTx = await escrow.unpause();
    await setUnpauseTx.wait();

    expect(await escrow.paused()).to.eq(false);
  });
});

describe('Set Order tests', function () {

  // working
  it("Should emit correct Event", async () => {
    escrow.connect(user_zk);

    let events = await escrow.queryFilter("*");
    const events_length = events.length;

    const setOrderTx = await escrow.set_order(user_eth, fee, {value});
    await setOrderTx.wait();
    
    events = await escrow.queryFilter("*");
    expect(events.length).to.equal(events_length + 1);
    expect(events[events.length - 1].fragment.name).to.equal("SetOrder");
  });

  // working
  it("Should get the order setted", async () => {
    escrow.connect(user_zk);

    const setOrderTx = await escrow.set_order(user_eth, fee, {value});
    await setOrderTx.wait();

    let events = await escrow.queryFilter("*");
    const newOrderEvent = events[events.length - 1];

    const orderId = newOrderEvent.args[0];

    const newOrder = await escrow.get_order(orderId);

    expect(newOrder[0]).to.eq(user_eth.address); //recipient_address
    expect(Number(newOrder[1])).to.eq(value-fee); //amount
    expect(Number(newOrder[2])).to.eq(fee); //fee

  })
})