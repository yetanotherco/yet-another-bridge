import { expect } from 'chai';
import { getWallet, deployContract, LOCAL_RICH_WALLETS } from '../deploy/utils';
import { Contract, Wallet } from 'ethers';
import * as hre from "hardhat";
import * as ethers from 'ethers';


export async function deployAndInit(): Promise<Contract> {

    const deployer = getWallet(LOCAL_RICH_WALLETS[0].privateKey);

    const escrow = await deployContract("Escrow", [], { wallet: deployer });
    
    //TODO deploy paymentregistry on L1 local
    const ethereum_payment_registry = "0x4337768cB3eC57Dd2cb843eFb929B773B13322de"; //process.env.PAYMENT_REGISTRY_PROXY_ADDRESS;
    const mm_ethereum_wallet = process.env.MM_ZKSYNC_WALLET;
    const mm_zksync_wallet = process.env.MM_ZKSYNC_WALLET;
    const native_token_eth_in_zksync = process.env.NATIVE_TOKEN_ETH_IN_ZKSYNC;
    if (!ethereum_payment_registry || !mm_ethereum_wallet || !mm_zksync_wallet || !native_token_eth_in_zksync) {
        console.log(ethereum_payment_registry,mm_ethereum_wallet,mm_zksync_wallet,native_token_eth_in_zksync);
        throw new Error("Missing required environment variables.");
    }

    escrow.connect(deployer);
    const initResult = await escrow.initialize(ethereum_payment_registry, mm_zksync_wallet);
    await initResult.wait();
    return escrow
}  

export async function deployPaymentRegistry(): Promise<Contract> {
    const deployer = getWallet(LOCAL_RICH_WALLETS[0].privateKey);

    const paymentRegistry = await deployContract("PaymentRegistry", [], { wallet: deployer });

    return await paymentRegistry.wait()
}
