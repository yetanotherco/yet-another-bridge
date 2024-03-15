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
    fn test_happy_path() {
        let (escrow, eth_token) = setup();

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'init: wrong balance');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'init: wrong balance');

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 500, 'set_order: wrong balance ');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'set_order: wrong balance');

        // check Order
        assert(order_id == 0, 'wrong order_id');
        let order_save = escrow.get_order(order_id);
        assert(order.recipient_address == order_save.recipient_address, 'wrong recipient_address');
        assert(order.amount == order_save.amount, 'wrong amount');
        assert(escrow.get_order_pending(order_id), 'wrong order used');

        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment'
        );

        let order_id_felt252: felt252 = order_id.try_into().unwrap();
        let recipient_address_felt252: felt252 = order.recipient_address.into();
        let amount_felt252: felt252 = order.amount.try_into().unwrap();

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@order_id_felt252, ref payload_buffer);
        Serde::serialize(@recipient_address_felt252, ref payload_buffer);
        Serde::serialize(@amount_felt252, ref payload_buffer);

        l1_handler.from_address = ETH_TRANSFER_CONTRACT().into();
        l1_handler.payload = payload_buffer.span();

        l1_handler.execute().expect('Failed to execute l1_handler');

        // check Order
        assert(!escrow.get_order_pending(order_id), 'wrong order used');
        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'withdraw: wrong balance');
        assert(eth_token.balanceOf(MM_STARKNET()) == 500, 'withdraw: wrong balance');
    }

    #[test]
    fn test_allowance_happy() {
        let (escrow, eth_token) = setup_approved(500);
        
        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 500, 'set_order: wrong balance ');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'set_order: wrong balance');
    }

    #[test]
    #[should_panic(expected: ('Not enough allowance',))]
    fn test_allowance_fail_allowance() {
        let (escrow, eth_token) = setup_approved(499);
        
        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Not enough balance',))]
    fn test_allowance_fail_balance() {
        let (escrow, eth_token) = setup_balance(499);
        
        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    // #[test]
    // fn test_fail_random_eth_user_calls_l1_handler() {
    //     let (escrow, _) = setup();
    //     let data: Array<felt252> = array![1, MM_ETHEREUM().into(), 3, 4];
    //     let mut payload_buffer: Array<felt252> = ArrayTrait::new();
    //     data.serialize(ref payload_buffer);
    //     let mut l1_handler = L1HandlerTrait::new(
    //         contract_address: escrow.contract_address,
    //         function_name: 'claim_payment',
    //     );
    //     l1_handler.from_address = ETH_USER().into();

    //     l1_handler.payload = payload_buffer.span();

    //     // same as "Should Panic" but for the L1 handler function
    //     match l1_handler.execute() {
    //         Result::Ok(_) => panic_with_felt252('shouldve panicked'),
    //         Result::Err(RevertedTransaction) => {
    //             assert(*RevertedTransaction.panic_data.at(0) == 'Only PAYMENT_REGISTRY_CONTRACT', *RevertedTransaction.panic_data.at(0));
    //         }
    //     }
    // }
    
    #[test]
    fn test_fail_random_eth_user_calls_l1_handler() {
        let (escrow, _) = setup();

        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment'
        );

        let order_id_felt252: felt252 = 1.try_into().unwrap();
        let recipient_address_felt252: felt252 = MM_ETHEREUM().into();
        
        let amount_felt252: felt252 = 1.try_into().unwrap();

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@order_id_felt252, ref payload_buffer);
        Serde::serialize(@recipient_address_felt252, ref payload_buffer);
        Serde::serialize(@amount_felt252, ref payload_buffer);

        l1_handler.from_address = ETH_USER().into();
        l1_handler.payload = payload_buffer.span();

        match l1_handler.execute() {
            Result::Ok(_) => panic_with_felt252('shouldve panicked'),
            Result::Err(RevertedTransaction) => {
                assert(*RevertedTransaction.panic_data.at(0) == 'Only PAYMENT_REGISTRY_CONTRACT', *RevertedTransaction.panic_data.at(0));
            }
        }
    }
}
