mod Escrow {
    use core::clone::Clone;
use core::option::OptionTrait;
use core::traits::TryInto;
use core::array::ArrayTrait;
use starknet::{EthAddress, ContractAddress};
    use integer::BoundedInt;

    use snforge_std::{declare, ContractClassTrait};
    use snforge_std::{CheatTarget, start_prank, stop_prank, L1Handler, L1HandlerTrait};

    use yab::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yab::escrow::{IEscrowDispatcher, IEscrowDispatcherTrait, Order};
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };
    use yab::tests::utils::constants::EscrowConstants::{
        USER, OWNER, MM_STARKNET, MM_ETHEREUM, ETH_TRANSFER_CONTRACT
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
        let evm_facts_registry = deploy_mock_EVMFactsRegistry();
        let escrow = deploy_escrow(
            evm_facts_registry.contract_address,
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
        herodotus_facts_registry_contract: ContractAddress,
        eth_transfer_contract: EthAddress,
        mm_ethereum_contract: EthAddress,
        mm_starknet_contract: ContractAddress,
        native_token_eth_starknet: ContractAddress
    ) -> IEscrowDispatcher {
        let escrow = declare('Escrow');
        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append(herodotus_facts_registry_contract.into());
        calldata.append(eth_transfer_contract.into());
        calldata.append(mm_ethereum_contract.into());
        calldata.append(mm_starknet_contract.into());
        calldata.append(native_token_eth_starknet.into());
        let address = escrow.deploy(@calldata).unwrap();
        return IEscrowDispatcher { contract_address: address };
    }

    fn deploy_mock_EVMFactsRegistry() -> IEVMFactsRegistryDispatcher {
        let mock_EVMFactsRegistry = declare('EVMFactsRegistry');
        let calldata: Array<felt252> = ArrayTrait::new();
        let address = mock_EVMFactsRegistry.deploy(@calldata).unwrap();
        return IEVMFactsRegistryDispatcher { contract_address: address };
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
        assert(!escrow.get_order_used(order_id), 'wrong order used');

        start_prank(CheatTarget::One(escrow.contract_address), MM_STARKNET());
        escrow.withdraw(order_id, 0, 0);
        stop_prank(CheatTarget::One(escrow.contract_address));

        // check Order
        assert(escrow.get_order_used(order_id), 'wrong order used');
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

    #[test]
    fn test_withdraw_batch() {
        let (escrow, eth_token) = setup();

        let recipient_addresses = array![12345.try_into().unwrap(), 12346.try_into().unwrap(), 12347.try_into().unwrap()];
        let amounts = array![500, 501, 502];
        let fees = array![3, 2, 1];

        let recipient_adresses_clone = recipient_addresses.clone();
        let amounts_clone = amounts.clone();

        let mut order_ids = array![];

        start_prank(CheatTarget::One(escrow.contract_address), USER());

        let mut idx = 0;
        loop {
            if idx >= 3 {
                break;
            }

            let recipient_address = recipient_addresses.at(idx).clone();
            let amount = amounts.at(idx).clone();
            let fee = fees.at(idx).clone();

            let order = Order { recipient_address, amount, fee };
            let order_id = escrow.set_order(order);

            order_ids.append(order_id);
            
            idx += 1;
        };

        stop_prank(CheatTarget::One(escrow.contract_address));

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 1509, 'set_order: wrong balance ');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'set_order: wrong balance');

        // Call withdraw_batch l1_handler
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'withdraw_batch'
        );

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@order_ids, ref payload_buffer);
        Serde::serialize(@recipient_adresses_clone, ref payload_buffer);
        Serde::serialize(@amounts_clone, ref payload_buffer);

        l1_handler.from_address = ETH_TRANSFER_CONTRACT().into();
        l1_handler.payload = payload_buffer.span();

        l1_handler.execute().expect('Failed to execute l1_handler');        
    }
}
