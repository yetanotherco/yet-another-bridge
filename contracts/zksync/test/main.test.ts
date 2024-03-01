import { expect } from 'chai';
import { deployAndInit } from './utils';
import { Contract } from 'ethers';

// let escrow: Contract;

// beforeEach( async () => {
//   escrow = await deployAndInit();
// });


describe('Pause tests', function () {

  it("Should start unpaused", async function () {
    const escrow = await deployAndInit();
    expect(await escrow.paused()).to.eq(false);
  });

  // it("Should pause", async function ()  {
  //   const escrow = await deployAndInit();

  //   const setPauseTx = await escrow.pause();

  //   await setPauseTx.wait();

  //   expect(await escrow.paused()).to.equal(true);
  // });

  // it("Should unpause", async function ()  {
  //   const escrow = await deployAndInit();

  //   const setPauseTx = await escrow.pause();
  //   await setPauseTx.wait();

  //   const setUnpauseTx = await escrow.unpause();
  //   await setUnpauseTx.wait();

  //   expect(await escrow.paused()).to.eq(false);
  // });
});
