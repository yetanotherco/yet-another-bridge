mod Escrow {
    use core::to_byte_array::FormatAsByteArray;
    use core::serde::Serde;
    use core::traits::Into;
    use starknet::{EthAddress, ContractAddress};
    use integer::BoundedInt;

    use snforge_std::{declare, ContractClassTrait, L1Handler, L1HandlerTrait};
    use snforge_std::{CheatTarget, start_prank, stop_prank, start_warp, stop_warp};

    use yab::mocks::mock_Escrow_changed_functions::{IEscrow_mock_changed_functionsDispatcher, IEscrow_mock_changed_functionsDispatcherTrait};
    use yab::mocks::mock_pausableEscrow::{IEscrow_mockPausableDispatcher, IEscrow_mockPausableDispatcherTrait};
    use yab::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yab::escrow::{IEscrowDispatcher, IEscrowDispatcherTrait, Order};
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };

    use yab::tests::utils::{
        constants::EscrowConstants::{
            USER, OWNER, MM_STARKNET, MM_ETHEREUM, ETH_TRANSFER_CONTRACT, ETH_USER
        },
    };

    use openzeppelin::{
        upgrades::{
            UpgradeableComponent,
            interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait}
        },
    };

    fn setup() -> (IEscrowDispatcher, IERC20Dispatcher) {
        setup_general(BoundedInt::max(), BoundedInt::max())
    }

    fn setup_approved(approved: u256) -> (IEscrowDispatcher, IERC20Dispatcher){
        setup_general(BoundedInt::max(), approved)
    }

    fn setup_balance(balance: u256) -> (IEscrowDispatcher, IERC20Dispatcher){
        setup_general(balance, BoundedInt::max())
    }

    fn setup_general(balance: u256, approved: u256) -> (IEscrowDispatcher, IERC20Dispatcher){
        let eth_token = deploy_erc20('ETH', '$ETH', BoundedInt::max(), OWNER());
        let escrow = deploy_escrow(
            OWNER(),
            ETH_TRANSFER_CONTRACT(),
            MM_ETHEREUM(),
            MM_STARKNET(),
            eth_token.contract_address
        );

        start_prank(CheatTarget::One(eth_token.contract_address), OWNER());
        eth_token.transfer(USER(), balance);
        stop_prank(CheatTarget::One(eth_token.contract_address));

        start_prank(CheatTarget::One(eth_token.contract_address), USER());
        eth_token.approve(escrow.contract_address, approved);
        stop_prank(CheatTarget::One(eth_token.contract_address));

        (escrow, eth_token)
    }

    fn deploy_escrow(
        escrow_owner: ContractAddress,
        eth_transfer_contract: EthAddress,
        mm_ethereum_contract: EthAddress,
        mm_starknet_contract: ContractAddress,
        native_token_eth_starknet: ContractAddress
    ) -> IEscrowDispatcher {
        let escrow = declare('Escrow');
        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append(escrow_owner.into());
        calldata.append(eth_transfer_contract.into());
        calldata.append(mm_ethereum_contract.into());
        calldata.append(mm_starknet_contract.into());
        calldata.append(native_token_eth_starknet.into());
        let address = escrow.deploy(@calldata).unwrap();
        return IEscrowDispatcher { contract_address: address };
    }
    
    fn deploy_erc20(
        name: felt252, symbol: felt252, initial_supply: u256, recipent: ContractAddress
    ) -> IERC20Dispatcher {
        let erc20 = declare('ERC20');
        let mut calldata = array![name, symbol];
        Serde::serialize(@initial_supply, ref calldata);
        calldata.append(recipent.into());
        let address = erc20.deploy(@calldata).unwrap();
        return IERC20Dispatcher { contract_address: address };
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_upgrade_escrow_caller_isnt_the_owner() {
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), MM_STARKNET());
        upgradeable.upgrade(declare('Escrow_mock_changed_functions').class_hash);
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_set_eth_transfer_contract() {
        let (escrow, _) = setup();
        escrow.set_eth_transfer_contract(MM_ETHEREUM());
    }

    #[test]
    fn test_set_eth_transfer_contract() {
        let (escrow, _) = setup();
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.set_eth_transfer_contract(MM_ETHEREUM());
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_set_mm_ethereum_contract() {
        let (escrow, _) = setup();
        escrow.set_mm_ethereum_contract(MM_ETHEREUM());
    }

    #[test]
    fn test_set_mm_ethereum_contract() {
        let (escrow, _) = setup();
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.set_mm_ethereum_contract(MM_ETHEREUM());
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_set_mm_starknet_contract() {
        let (escrow, _) = setup();
        escrow.set_mm_starknet_contract(USER());
    }

    #[test]
    fn test_set_mm_starknet_contract() {
        let (escrow, _) = setup();
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.set_mm_starknet_contract(USER());
    }
}
