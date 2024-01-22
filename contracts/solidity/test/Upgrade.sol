// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {YABTransfer_lessVars} from "./mock_contracts/YABTransfer_lessVars.sol";
import {YABTransfer_reorgVars} from "./mock_contracts/YABTransfer_reorgVars.sol";
import {YABTransfer_replaceVars} from "./mock_contracts/YABTransfer_replaceVars.sol";
import {YABTransfer_moreVars_before} from "./mock_contracts/YABTransfer_moreVars_before.sol";
import {YABTransfer_moreVars_after} from "./mock_contracts/YABTransfer_moreVars_after.sol";


contract TransferTest is Test {
    address public deployer = address(0xB321099cf86D9BB913b891441B014c03a6CcFc54);

    YABTransfer public yab;
    ERC1967Proxy public proxy;
    YABTransfer public yab_caller;

    function setUp() public {
        vm.startPrank(deployer);

        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
        
        yab = new YABTransfer();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = YABTransfer(address(proxy));
        yab_caller.initialize(snMessagingAddress, snEscrowAddress, snEscrowWithdrawSelector);

        vm.stopPrank();
    }


    //// The following functions use always the same Proxy to upgrade the smart contract to different versions of it:
    
    // Same as original
    function deploy_and_upgrade_oldVars() public returns (YABTransfer){
        YABTransfer yab_old = new YABTransfer();
        YABTransfer yab_old_caller = YABTransfer(address(proxy));
        yab_old_caller.upgradeToAndCall(address(yab_old), '');
        return yab_old_caller;
    }

    // Same as original but with less variables
    function deploy_and_upgrade_lessVars() public returns (YABTransfer_lessVars){
        YABTransfer_lessVars yab_lessVars = new YABTransfer_lessVars();
        YABTransfer_lessVars yab_lessVars_caller = YABTransfer_lessVars(address(proxy));
        yab_lessVars_caller.upgradeToAndCall(address(yab_lessVars), '');
        return yab_lessVars_caller;
    }

    // Same as original but with reordered variables
    function deploy_and_upgrade_reorgVars() public returns (YABTransfer_reorgVars){
        YABTransfer_reorgVars yab_reorgVars = new YABTransfer_reorgVars();
        YABTransfer_reorgVars yab_reorgVars_caller = YABTransfer_reorgVars(address(proxy));
        yab_reorgVars_caller.upgradeToAndCall(address(yab_reorgVars), '');
        return yab_reorgVars_caller;
    }

    // Same as original but with replaced variables
    function deploy_and_upgrade_replaceVars() public returns (YABTransfer_replaceVars){
        YABTransfer_replaceVars yab_replaceVars = new YABTransfer_replaceVars();
        YABTransfer_replaceVars yab_replaceVars_caller = YABTransfer_replaceVars(address(proxy));
        yab_replaceVars_caller.upgradeToAndCall(address(yab_replaceVars), '');
        return yab_replaceVars_caller;
    }

    // Same as original but with more variables at the beggining of the storage
    function deploy_and_upgrade_moreVars_before() public returns (YABTransfer_moreVars_before){
        YABTransfer_moreVars_before yab_moreVars_before = new YABTransfer_moreVars_before();
        YABTransfer_moreVars_before yab_moreVars_before_caller = YABTransfer_moreVars_before(address(proxy));
        yab_moreVars_before_caller.upgradeToAndCall(address(yab_moreVars_before), '');
        return yab_moreVars_before_caller;
    }

    // Same as original but with more variables at the end of the storage
    function deploy_and_upgrade_moreVars_after() public returns (YABTransfer_moreVars_after){
        YABTransfer_moreVars_after yab_moreVars_after = new YABTransfer_moreVars_after();
        YABTransfer_moreVars_after yab_moreVars_after_caller = YABTransfer_moreVars_after(address(proxy));
        yab_moreVars_after_caller.upgradeToAndCall(address(yab_moreVars_after), '');
        return yab_moreVars_after_caller;
    }
    
    //// ^^ Functions to upgrade the smart contract ^^


    function test_read_values() public { //ok
        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);
    }

    function test_delete_undelete_values() public {
        vm.startPrank(deployer);

        deploy_and_upgrade_lessVars();
        YABTransfer yab_oldVars_caller = deploy_and_upgrade_oldVars();

        assertEq(yab_oldVars_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_oldVars_caller.getEscrowAddress(), 0x0 );
        
        vm.stopPrank();
    }

    // WARNING
    function test_replace_values() public { //this test proves new vars take the memory slot of replaced vars
        vm.startPrank(deployer);
        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);

        YABTransfer_replaceVars yab_replaceVars_caller = deploy_and_upgrade_replaceVars();

        assertEq(yab_replaceVars_caller.getEscrowWithdrawSelectorV2(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_replaceVars_caller.getEscrowAddressV2(), 0x0);
        
        vm.stopPrank();
    }

    // WARNING
    function test_delete_replace_values() public { //this test proves new vars take the memory slot of old deleted vars
        vm.startPrank(deployer);
        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);

        deploy_and_upgrade_lessVars();
        YABTransfer_replaceVars yab_replaceVars_caller = deploy_and_upgrade_replaceVars();

        assertEq(yab_replaceVars_caller.getEscrowWithdrawSelectorV2(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_replaceVars_caller.getEscrowAddressV2(), 0x0);
        
        vm.stopPrank();
    }

    //WARNING
    function test_read_reorg_values() public { //this test proves reorganizing values in storage IS HIGHLY DANGEROUS
        vm.startPrank(deployer);
        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);

        YABTransfer_reorgVars yab_reorgVars_caller = deploy_and_upgrade_reorgVars();

        assertEq(yab_reorgVars_caller.getEscrowWithdrawSelector(), 0x0);
        assertEq(yab_reorgVars_caller.getEscrowAddress(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        vm.stopPrank();
    }

    //WARNING
    function test_read_delAndReorg_values() public {//this test proves reorganizing values in storage IS HIGHLY DANGEROUS
        vm.startPrank(deployer);
        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);

        deploy_and_upgrade_lessVars();
        YABTransfer_reorgVars yab_reorgVars_caller = deploy_and_upgrade_reorgVars();

        assertEq(yab_reorgVars_caller.getEscrowWithdrawSelector(), 0x0);
        assertEq(yab_reorgVars_caller.getEscrowAddress(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        vm.stopPrank();
    }
    
    //WARNING
    function test_add_var_before() public { //This test proves adding new variables at the beggining of the storage is highly dangerous
        vm.startPrank(deployer);

        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);

        YABTransfer_moreVars_before yab_moreVars_before_caller =  deploy_and_upgrade_moreVars_before();

        assertEq(yab_moreVars_before_caller.getNewVarBefore(), 0x0);
        assertEq(yab_moreVars_before_caller.getEscrowWithdrawSelector(), 0x0); //this value has been swapped
        assertEq(yab_moreVars_before_caller.getEscrowAddress(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77); //this value has been swapped
        vm.stopPrank();
    }

    function test_add_var_after() public { //This test shows how adding vars at the end of the storage is the best way to go
        vm.startPrank(deployer);

        assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_caller.getEscrowAddress(), 0x0);

        YABTransfer_moreVars_after yab_moreVars_after_caller =  deploy_and_upgrade_moreVars_after();

        assertEq(yab_moreVars_after_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
        assertEq(yab_moreVars_after_caller.getEscrowAddress(), 0x0);
        assertEq(yab_moreVars_after_caller.getNewVarAfter(), 0x0);
        vm.stopPrank();
    }
}
