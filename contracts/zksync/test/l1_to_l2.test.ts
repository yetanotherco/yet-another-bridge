import { expect, use } from 'chai';
import { deployAndInit, deployPaymentRegistry } from './utils';
import { Contract, Fragment, Wallet } from 'ethers';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';

let escrow: Contract;
let paymentRegistry: Contract;

let deployer: Wallet = getWallet(LOCAL_RICH_WALLETS[0].privateKey);
let user_zk: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);
let user_eth: Wallet = getWallet(LOCAL_RICH_WALLETS[1].privateKey);

const fee = 1; //TODO check, maybe make fuzz
const value = 10; //TODO check, maybe make fuzz

beforeEach( async () => {
  paymentRegistry = await deployPaymentRegistry();
  escrow = await deployAndInit();
});


//WIP, missing integrating PaymentRegistry to testing environment
describe('L1 to L2', function () {

  it("Should claim payment", async function ()  {
    escrow.connect(user_zk);
    const setOrderTx = await escrow.set_order(user_eth, fee, {value});
    await setOrderTx.wait();

  });
});