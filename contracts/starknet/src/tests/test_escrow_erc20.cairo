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
    use yab::escrow::{IEscrowDispatcher, IEscrowDispatcherTrait, Order, OrderERC20};
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };

    use yab::tests::utils::{
        constants::EscrowConstants::{
            USER, OWNER, MM_STARKNET, MM_ETHEREUM, ETH_TRANSFER_CONTRACT, ETH_USER, ETH_USER_2, ETH_USER_3, L1_ERC20_ADDRESS
        },
    };

    use openzeppelin::{
        upgrades::{
            UpgradeableComponent,
            interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait}
        },
    };

    fn setup_with_erc20() -> (IEscrowDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        setup_general_with_erc20(BoundedInt::max(), BoundedInt::max())
    }

    fn setup_general_with_erc20(balance: u256, approved: u256) -> (IEscrowDispatcher, IERC20Dispatcher, IERC20Dispatcher){
        let (eth_token, uri_token) = deploy_erc20_2('ETH', '$ETH', BoundedInt::max(), OWNER(), 'UriCoin', '$Uri', BoundedInt::max(), USER());

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

        start_prank(CheatTarget::One(uri_token.contract_address), USER());
        uri_token.approve(escrow.contract_address, approved);
        stop_prank(CheatTarget::One(uri_token.contract_address));

        (escrow, eth_token, uri_token)
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

    fn deploy_erc20_2( //without this, the declare('ERC20') line is called twice, causing the execution to crash
        name: felt252, symbol: felt252, initial_supply: u256, recipent: ContractAddress, name_2: felt252, symbol_2: felt252, initial_supply_2: u256, recipent_2: ContractAddress
    ) -> (IERC20Dispatcher, IERC20Dispatcher) {
        let erc20 = declare('ERC20');
        let mut calldata = array![name, symbol];
        Serde::serialize(@initial_supply, ref calldata);
        calldata.append(recipent.into());
        let address = erc20.deploy(@calldata).unwrap();

        let mut calldata_2 = array![name_2, symbol_2];
        Serde::serialize(@initial_supply_2, ref calldata_2);
        calldata_2.append(recipent_2.into());
        let address_2 = erc20.deploy(@calldata_2).unwrap();

        return (IERC20Dispatcher { contract_address: address }, IERC20Dispatcher { contract_address: address_2 });
    }

    #[test]
    fn test_claim_payment_erc20() {
        let (escrow, eth_token, uri_token) = setup_with_erc20();

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'init: wrong balance 1');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'init: wrong balance 2');

        assert(uri_token.balanceOf(escrow.contract_address) == 0, 'init: wrong balance 3');
        assert(uri_token.balanceOf(USER()) == BoundedInt::max(), 'init: wrong balance 4');
        assert(uri_token.balanceOf(MM_STARKNET()) == 0, 'init: wrong balance 5');

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order_erc20 = OrderERC20 { recipient_address: ETH_USER(), amount_l2: 200, amount_l1: 100, fee: 10, l2_erc20_address: uri_token.contract_address, l1_erc20_address: L1_ERC20_ADDRESS() };
        let order_id = escrow.set_order_erc20(order_erc20);
        stop_prank(CheatTarget::One(escrow.contract_address));

        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 10, 'set_order: wrong balance ');
        assert(eth_token.balanceOf(MM_STARKNET()) == 0, 'set_order: wrong balance');

        assert(uri_token.balanceOf(escrow.contract_address) == 200, 'init: wrong balance 3');
        assert(uri_token.balanceOf(USER()) == BoundedInt::max()-200, 'init: wrong balance 4');
        assert(uri_token.balanceOf(MM_STARKNET()) == 0, 'init: wrong balance 5');

        // check Order
        assert(order_id == 0, 'wrong order_id');
        let order_save = escrow.get_order_erc20(order_id);
        assert(order_erc20.recipient_address == order_save.recipient_address, 'wrong recipient_address');
        assert(order_erc20.amount_l2 == order_save.amount_l2, 'wrong amount_l2');
        assert(order_erc20.amount_l1 == order_save.amount_l1, 'wrong amount_l1');
        assert(order_erc20.fee == order_save.fee, 'wrong fee');
        assert(order_erc20.l2_erc20_address == order_save.l2_erc20_address, 'wrong l2_erc20_address');
        assert(order_erc20.l1_erc20_address == order_save.l1_erc20_address, 'wrong l1_erc20_address');
        assert(escrow.get_order_pending(order_id), 'wrong order used');

        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment_erc20'
        );

        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@order_id, ref payload_buffer);
        Serde::serialize(@order_erc20.recipient_address, ref payload_buffer);
        Serde::serialize(@order_erc20.amount_l1, ref payload_buffer);
        Serde::serialize(@order_erc20.l1_erc20_address, ref payload_buffer);

        l1_handler.from_address = ETH_TRANSFER_CONTRACT().into();
        l1_handler.payload = payload_buffer.span();

        l1_handler.execute().expect('Failed to execute l1_handler');

        // check Order
        assert(!escrow.get_order_pending(order_id), 'wrong order used');
        // check balance
        assert(eth_token.balanceOf(escrow.contract_address) == 0, 'withdraw: wrong balance');
        assert(eth_token.balanceOf(MM_STARKNET()) == 10, 'withdraw: wrong balance');

        assert(uri_token.balanceOf(escrow.contract_address) == 0, 'init: wrong balance');
        assert(uri_token.balanceOf(MM_STARKNET()) == 200, 'init: wrong balance');
    }

    #[test]
    fn test_fail_random_eth_user_calls_l1_handler() {
        let (escrow, _, _) = setup_with_erc20();
        let data: Array<felt252> = array![1, MM_ETHEREUM().into(), 3, L1_ERC20_ADDRESS().into(), 5];
        let mut payload_buffer: Array<felt252> = ArrayTrait::new();
        data.serialize(ref payload_buffer);
        let mut l1_handler = L1HandlerTrait::new(
            contract_address: escrow.contract_address,
            function_name: 'claim_payment_erc20',
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
}
