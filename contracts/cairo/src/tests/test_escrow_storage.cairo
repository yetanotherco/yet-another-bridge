mod Escrow {
    use core::to_byte_array::FormatAsByteArray;
    use core::serde::Serde;
    use core::traits::Into;
    use starknet::{EthAddress, ContractAddress};
    use integer::BoundedInt;

    use snforge_std::{declare, ContractClassTrait, L1Handler, L1HandlerTrait};
    use snforge_std::{CheatTarget, start_prank, stop_prank};

    use yab::mocks::mock_Escrow_changed_functions::{IEscrow_changed_functionsDispatcher, IEscrow_changed_functionsDispatcherTrait};
    use yab::mocks::mock_Escrow_lessVars::{IEscrow_lessVarsDispatcher, IEscrow_lessVarsDispatcherTrait};
    use yab::mocks::mock_Escrow_moreVars_before::{IEscrow_moreVars_beforeDispatcher, IEscrow_moreVars_beforeDispatcherTrait};
    use yab::mocks::mock_Escrow_moreVars_after::{IEscrow_moreVars_afterDispatcher, IEscrow_moreVars_afterDispatcherTrait};
    use yab::mocks::mock_Escrow_reorgVars::{IEscrow_reorgVarsDispatcher, IEscrow_reorgVarsDispatcherTrait};
    use yab::mocks::mock_Escrow_replaceVars::{IEscrow_replaceVarsDispatcher, IEscrow_replaceVarsDispatcherTrait};
    use yab::mocks::mock_Escrow_oldVars::{IEscrow_oldVarsDispatcher, IEscrow_oldVarsDispatcherTrait};
    use yab::mocks::mock_Escrow_replacePlusOldVars::{IEscrow_replacePlusOldVarsDispatcher, IEscrow_replacePlusOldVarsDispatcherTrait};


    use yab::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yab::escrow::{IEscrowDispatcher, IEscrowDispatcherTrait, Order};
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };

    use yab::tests::utils::{
        constants::EscrowConstants::{
            USER, OWNER, MM_STARKNET, MM_ETHEREUM, ETH_TRANSFER_CONTRACT
        },
    };

    use openzeppelin::{
        upgrades::{
            UpgradeableComponent,
            interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait}
        },
    };

    use debug::PrintTrait;

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
    fn test_upgrade_escrow() {
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order = Order { recipient_address: 12345.try_into().unwrap(), amount: 500, fee: 0 };
        let order_id = escrow.set_order(order);
        let order_save = escrow.get_order(order_id);
        stop_prank(CheatTarget::One(escrow.contract_address));

        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        upgradeable.upgrade(declare('Escrow_changed_functions').class_hash);
        let upgraded_escrow = IEscrow_changed_functionsDispatcher { contract_address: escrow.contract_address };
        
        stop_prank(CheatTarget::One(escrow.contract_address));

        start_prank(CheatTarget::One(escrow.contract_address), USER());
        let order_new = upgraded_escrow.get_order_V2(order_id); //shouldn't be possible if the contract was not upgraded
        assert(order_new.recipient_address == order_save.recipient_address, 'wrong recipient_address');
        assert(order_new.amount == order_save.amount, 'wrong amount');
        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_fail_upgrade_escrow_caller_isnt_the_owner() {
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), MM_STARKNET());
        upgradeable.upgrade(declare('Escrow_changed_functions').class_hash);
    }

    // //this test helps to prove upgrading works as intended
    // //but as it is an exception it says "failed" when run
    // #[test]
    // #[should_panic(expected: ('Entry point selector 0x009033a93ae22bbe3345b5bc992840aa932bf44027c3e662056eed95d7f0a4e4 not found in contract 0x046265009a15985a37f39b3998e2744c33c43ed269789871cf5b66c38e01e4ec',))]
    // fn test_upgrade_escrow_nigger() {
    //     let (escrow, _) = setup();
    //     let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
    //     start_prank(CheatTarget::One(escrow.contract_address), OWNER());
    //     let a = escrow.get_mm_starknet_contract();
    //     let b = escrow.get_mm_ethereum_contract();
    //     a.print();
    //     b.print();
    //     'asdasdasd'.print();

    //     upgradeable.upgrade(declare('Escrow_lessVars').class_hash);

    //     let c = escrow.get_mm_starknet_contract();
    //     let d = escrow.get_mm_ethereum_contract();
    //     c.print();
    //     d.print();
    //     stop_prank(CheatTarget::One(escrow.contract_address));
    // }

    #[test]
    fn test_delete_restore_var() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_lessVars').class_hash);
        upgradeable.upgrade(declare('Escrow_oldVars').class_hash);
        let upgraded_escrow = IEscrow_oldVarsDispatcher { contract_address: escrow.contract_address };

        let sn_af = upgraded_escrow.get_mm_starknet_contract();
        let eth_af = upgraded_escrow.get_mm_ethereum_contract();

        assert(sn_bf == sn_af, 'sn changed value');
        assert(eth_bf == eth_af, 'eth changed value');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_add_var_after() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_moreVars_after').class_hash);
        let upgraded_escrow = IEscrow_moreVars_afterDispatcher { contract_address: escrow.contract_address };

        let sn_af = upgraded_escrow.get_mm_starknet_contract();
        let eth_af = upgraded_escrow.get_mm_ethereum_contract();
        let new_var: u256 = 123456;
        upgraded_escrow.set_new_var_after(new_var);

        assert(sn_bf == sn_af, 'sn changed value');
        assert(eth_bf == eth_af, 'eth changed value');
        assert(upgraded_escrow.get_new_var_after() == new_var, 'new_var error');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_add_var_before() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_moreVars_before').class_hash);
        let upgraded_escrow = IEscrow_moreVars_beforeDispatcher { contract_address: escrow.contract_address };

        let sn_af = upgraded_escrow.get_mm_starknet_contract();
        let eth_af = upgraded_escrow.get_mm_ethereum_contract();
        let new_var: u256 = 123456;
        upgraded_escrow.set_new_var_before(new_var);

        assert(sn_bf == sn_af, 'sn changed value');
        assert(eth_bf == eth_af, 'eth changed value');
        assert(upgraded_escrow.get_new_var_before() == new_var, 'new_var error');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_reorg_vars() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_reorgVars').class_hash);
        let upgraded_escrow = IEscrow_reorgVarsDispatcher { contract_address: escrow.contract_address };

        let sn_af = upgraded_escrow.get_mm_starknet_contract();
        let eth_af = upgraded_escrow.get_mm_ethereum_contract();

        assert(sn_bf == sn_af, 'sn changed value');
        assert(eth_bf == eth_af, 'eth changed value');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_replace_vars_() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_replaceVars').class_hash);
        let upgraded_escrow = IEscrow_replaceVarsDispatcher { contract_address: escrow.contract_address };

        let sn_v2_af = upgraded_escrow.get_mm_starknet_contract_V2();
        let eth_v2_af = upgraded_escrow.get_mm_ethereum_contract_V2();

        assert(sn_bf != sn_v2_af, 'sn_v2 took the value of sn');
        assert(eth_bf != eth_v2_af, 'eth_v2 took the value of eth');
        assert(eth_v2_af == 0.try_into().unwrap(), 'eth_v2 took some value');
        assert(sn_v2_af == 0.try_into().unwrap(), 'sn_v2 took some value');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_delete_replace_restore_var() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_lessVars').class_hash);
        upgradeable.upgrade(declare('Escrow_replaceVars').class_hash);
        upgradeable.upgrade(declare('Escrow_oldVars').class_hash);
        let upgraded_escrow = IEscrow_oldVarsDispatcher { contract_address: escrow.contract_address };

        let sn_af = upgraded_escrow.get_mm_starknet_contract();
        let eth_af = upgraded_escrow.get_mm_ethereum_contract();

        assert(sn_bf == sn_af, 'sn changed value');
        assert(eth_bf == eth_af, 'eth changed value');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

    #[test]
    fn test_delete_replace_restore_var_2() { //ok
        let (escrow, _) = setup();
        let upgradeable = IUpgradeableDispatcher { contract_address: escrow.contract_address };
        start_prank(CheatTarget::One(escrow.contract_address), OWNER());
        let sn_bf = escrow.get_mm_starknet_contract();
        let eth_bf = escrow.get_mm_ethereum_contract();

        upgradeable.upgrade(declare('Escrow_lessVars').class_hash);
        upgradeable.upgrade(declare('Escrow_replaceVars').class_hash);
        upgradeable.upgrade(declare('Escrow_replacePlusOldVars').class_hash);
        let upgraded_escrow = IEscrow_replacePlusOldVarsDispatcher { contract_address: escrow.contract_address };

        let sn_af = upgraded_escrow.get_mm_starknet_contract_old();
        let eth_af = upgraded_escrow.get_mm_ethereum_contract_old();

        assert(sn_bf == sn_af, 'sn changed value');
        assert(eth_bf == eth_af, 'eth changed value');

        stop_prank(CheatTarget::One(escrow.contract_address));
    }

}
