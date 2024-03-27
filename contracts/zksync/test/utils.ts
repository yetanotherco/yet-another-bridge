import { expect } from 'chai';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';
import { Contract, Wallet } from 'ethers';
import * as hre from "hardhat";
import * as ethers from 'ethers';


export async function deployAndInit(): Promise<Contract> {

    const deployer = getWallet(LOCAL_RICH_WALLETS[0].privateKey);

    const escrow = await deployContract("Escrow", [], { wallet: deployer });
    
    const ethereum_payment_registry = LOCAL_RICH_WALLETS[3].address; //semi-random address, prefunded to mock calls from this address

    const mm_ethereum_wallet = process.env.MM_ZKSYNC_WALLET;
    const mm_zksync_wallet = process.env.MM_ZKSYNC_WALLET;
    if (!ethereum_payment_registry || !mm_ethereum_wallet || !mm_zksync_wallet) {
        console.log(ethereum_payment_registry,mm_ethereum_wallet,mm_zksync_wallet);
        throw new Error("Missing required environment variables.");
    }

    escrow.connect(deployer);
    const initResult = await escrow.initialize(ethereum_payment_registry, mm_zksync_wallet);
    await initResult.wait();
    return escrow
}  
