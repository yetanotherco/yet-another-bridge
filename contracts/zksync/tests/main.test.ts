import { expect } from 'chai';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';

describe('Escrow', function () {
  it("Should return the new paused state once it's changed", async function () {
    const wallet = getWallet(LOCAL_RICH_WALLETS[0].privateKey);

    const escrow = await deployContract("Escrow", [], { wallet, silent: true });

    expect(await escrow.paused()).to.eq(false);


    const setPausedTx = await escrow.pause();
    
    // wait until the transaction is processed
    await setPausedTx.wait();

    expect(await escrow.paused()).to.equal(true);
  });
});
