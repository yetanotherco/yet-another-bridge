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
            interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait},
        },
        security::{
            PausableComponent,
            interface::{IPausable, IPausableDispatcher, IPausableDispatcherTrait},
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
    fn test_start_unpaused() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        assert(pausable.is_paused() == false, 'Should start unpaused');
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_pause() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.pause();
        assert(pausable.is_paused() == true, 'Should be paused');
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_pause_unpause() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        assert(pausable.is_paused() == false, 'Should start unpaused');
        escrow.pause();
        assert(pausable.is_paused() == true, 'Should be paused');
        escrow.unpause();
        assert(pausable.is_paused() == false, 'Should be unpaused');
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_pause_not_owner() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        assert(pausable.is_paused() == false, 'Should start unpaused');
        escrow.pause();
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_unpause_not_owner() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        assert(pausable.is_paused() == false, 'Should start unpaused');
        escrow.pause();
        assert(pausable.is_paused() == true, 'Should be paused');
        stop_prank(CheatTarget::One(escrow.contract_address));
        
        start_prank(CheatTarget::One(escrow.contract_address), USER());
        escrow.unpause();
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Pausable: paused',))]
    fn test_fail_pause_while_paused() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        assert(pausable.is_paused() == false, 'Should start unpaused');
        escrow.pause();
        assert(pausable.is_paused() == true, 'Should be paused');
        escrow.pause();
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Pausable: not paused',))]
    fn test_fail_unpause_while_unpaused() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        assert(pausable.is_paused() == false, 'Should start unpaused');
        escrow.unpause();
        assert(pausable.is_paused() == false, 'Should be unpaused');
        escrow.unpause();
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Pausable: paused',))]
    fn test_fail_set_order_when_paused() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.pause();
        stop_prank(CheatTarget::One(escrow.contract_address));

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));
    }
    
    #[test]
    fn test_set_order_when_unpaused_after_prev_pause() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };


        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.pause();
        escrow.unpause();
        stop_prank(CheatTarget::One(escrow.contract_address));

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));
    }
    
    #[test]
    fn test_upgrade_when_paused() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.pause();
        upgradeable.upgrade(declare('Escrow_mockPausable').class_hash);

        let escrow_2 = IEscrow_mockPausableDispatcher { contract_address: escrow.contract_address };
        assert(escrow_2.pause_state() == true, 'Contract should be paused');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_fail_call_l1_handler_while_paused() {
        let (escrow, _) = setup();
        let pausable = IPausableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        escrow.pause();
        stop_prank(CheatTarget::One(escrow.contract_address));

        let data: Array<felt252> = array![1, MM_ETHEREUM().into(), 3, 4];
        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        data.serialize(ref payload_buffer);
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment',
        );
        l1_handler.from_address = ETH_TRANSFER_CONTRACT().into();
        l1_handler.payload = payload_buffer.span();

        // same as "Should Panic" but for the L1 handler function
        match l1_handler.execute() {
            Result::Ok(_) => panic_with_felt252('shouldve panicked'),
            Result::Err(RevertedTransaction) => {
                assert(*RevertedTransaction.panic_data.at(0) == 'Pausable: paused', *RevertedTransaction.panic_data.at(0));
            }
        }
    }
}
