import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract, Wallet } from 'ethers';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';

let escrow: Contract;
let deployer: Wallet;

beforeEach( async () => {
  escrow = await deployAndInit();
  deployer = getWallet(LOCAL_RICH_WALLETS[0].privateKey);
});


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
