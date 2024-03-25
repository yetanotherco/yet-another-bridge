mod Escrow {
    use core::array::ArrayTrait;
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
            USER, OWNER, MM_STARKNET, MM_ETHEREUM, ETH_TRANSFER_CONTRACT, ETH_USER, ETH_USER_2, ETH_USER_3
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

    // fn setup_approved(approved: u256) -> (IEscrowDispatcher, IERC20Dispatcher){
    //     setup_general(BoundedInt::max(), approved)
    // }

    // fn setup_balance(balance: u256) -> (IEscrowDispatcher, IERC20Dispatcher){
    //     setup_general(balance, BoundedInt::max())
    // }

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

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@order_id, ref payload_buffer);
        Serde::serialize(@order.recipient_address, ref payload_buffer);
        Serde::serialize(@order.amount, ref payload_buffer);

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
    fn test_claim_batch_happy() {
        let (escrow, eth_token) = setup();

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'init: wrong balance');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'init: wrong balance');

        let recipient_addresses = array![ETH_USER(), ETH_USER_2(), ETH_USER_3()];
        let amounts = array![500, 501, 502];
        let fees = array![3, 2, 1];

        let recipient_adresses_clone = recipient_addresses.clone();
        let amounts_clone = amounts.clone();

        let mut orders = array![];

        start_prank(CheatTarget::One(escrow.contract_address), USER());

        let mut idx = 0;
        loop {
            if idx >= 3 {
                break;
            }

            let recipient_address = recipient_addresses.at(idx).clone();
            let amount = amounts.at(idx).clone();
            let fee = fees.at(idx).clone();

            let order_id = _create_order(recipient_address, amount, fee, escrow);

            orders.append((order_id, recipient_address, amount));
            
            idx += 1;
        };

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 1509, 'set_order: wrong balance ');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'set_order: wrong balance');

        // Call withdraw_batch l1_handler
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment_batch'
        );

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@orders, ref payload_buffer);

        l1_handler.from_address = ETH_TRANSFER_CONTRACT().into();
        l1_handler.payload = payload_buffer.span();

        l1_handler.execute().expect('Failed to execute l1_handler');     

        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'withdraw: wrong balance');
        assert(eth_token.balanceOf(MM_STARKNET()) == 1509, 'withdraw: wrong balance');

        // Check order_ids
        let mut idx = 0;
        loop {
            if idx >= 3 {
                break;
            }

            let (order_id, _, _) = orders.at(idx).clone();
            assert(!escrow.get_order_pending(order_id), 'Order not used');
            idx += 1;
        };
    }

    #[test]
    fn test_claim_batch_fail_missing_order_id() {
        let (escrow, eth_token) = setup();

        let mut orders = array![];

        let amount = 500;
        let order_id = _create_order(ETH_USER(), amount, 1, escrow);

        orders.append((order_id, ETH_USER(), amount));
        orders.append((order_id + 1, ETH_USER_2(), amount));

        // Call withdraw_batch l1_handler
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment_batch'
        );

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@orders, ref payload_buffer);

        l1_handler.from_address = ETH_TRANSFER_CONTRACT().into();
        l1_handler.payload = payload_buffer.span();

        // same as "Should Panic" but for the L1 handler function
        match l1_handler.execute() {
            Result::Ok(_) => panic_with_felt252('shouldve panicked'),
            Result::Err(RevertedTransaction) => {
                assert(*RevertedTransaction.panic_data.at(0) == 'Order withdrew or nonexistent', *RevertedTransaction.panic_data.at(0));
            }
        } 
    }

    #[test]
    fn test_fail_random_eth_user_calls_l1_handler() {
        let (escrow, _) = setup();
        let data: Array<felt252> = array![1, MM_ETHEREUM().into(), 3, 4];
        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        data.serialize(ref payload_buffer);
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment',
        );
        l1_handler.from_address = ETH_USER().into();

        l1_handler.payload = payload_buffer.span();

        // same as "Should Panic" but for the L1 handler function
        match l1_handler.execute() {
            Result::Ok(_) => panic_with_felt252('shouldve panicked'),
            Result::Err(RevertedTransaction) => {
                assert(*RevertedTransaction.panic_data.at(0) == 'Only PAYMENT_REGISTRY_CONTRACT', *RevertedTransaction.panic_data.at(0));
            }
        }
    }

    #[test]
    fn test_fail_random_eth_user_calls_l1_handler_batch() {
        let (escrow, eth_token) = setup();

        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'init: wrong balance');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'init: wrong balance');

        let recipient_addresses = array![12345.try_into().unwrap(), 12346.try_into().unwrap(), 12347.try_into().unwrap()];
        let amounts = array![500, 501, 502];
        let fees = array![3, 2, 1];

        let recipient_adresses_clone = recipient_addresses.clone();
        let amounts_clone = amounts.clone();

        let mut orders = array![];

        start_prank(CheatTarget::One(escrow.contract_address), USER());

        let mut idx = 0;
        loop {
            if idx >= 3 {
                break;
            }

            let recipient_address = recipient_addresses.at(idx).clone();
            let amount = amounts.at(idx).clone();
            let fee = fees.at(idx).clone();

            let order_id = _create_order(recipient_address, amount, fee, escrow);

            orders.append((order_id, recipient_address, amount));
            
            idx += 1;
        };

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 1509, 'set_order: wrong balance ');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'set_order: wrong balance');

        // Call withdraw_batch l1_handler
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment_batch'
        );

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@orders, ref payload_buffer);

        l1_handler.payload = payload_buffer.span();
        l1_handler.from_address = ETH_USER().into();

        // same as "Should Panic" but for the L1 handler function
        match l1_handler.execute() {
            Result::Ok(_) => panic_with_felt252('shouldve panicked'),
            Result::Err(RevertedTransaction) => {
                assert(*RevertedTransaction.panic_data.at(0) == 'Only PAYMENT_REGISTRY_CONTRACT', *RevertedTransaction.panic_data.at(0));
            }
        }
    }

    fn _create_order(
        recipient_address: EthAddress, 
        amount: u256, 
        fee: u256, 
        escrow: IEscrowDispatcher,
    ) -> u256 {
        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: recipient_address.try_into().unwrap(), amount: amount, fee: fee };
        let order_id = escrow.set_order(order);
        stop_prank(CheatTarget::One(escrow.contract_address));
        return order_id;
    }
}
