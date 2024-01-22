// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {YABTransfer_lessVars} from "./mock_contracts/YABTransfer_lessVars.sol";
import {YABTransfer_reorgVars} from "./mock_contracts/YABTransfer_reorgVars.sol";
import {YABTransfer_moreVars_before} from "./mock_contracts/YABTransfer_moreVars_before.sol";
import {YABTransfer_moreVars_after} from "./mock_contracts/YABTransfer_moreVars_after.sol";


contract TransferTest is Test {
    address public deployer = address(0xB321099cf86D9BB913b891441B014c03a6CcFc54);
    address public marketMaker;

    YABTransfer public yab;
    ERC1967Proxy public proxy;
    YABTransfer public yab_caller;

    function setUp() public {
        vm.startPrank(deployer);

        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
        marketMaker = 0xda963fA72caC2A3aC01c642062fba3C099993D56;
        
        yab = new YABTransfer();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = YABTransfer(address(proxy));
        yab_caller.initialize(snMessagingAddress, snEscrowAddress, snEscrowWithdrawSelector, marketMaker);

        vm.stopPrank();
    }

    function deploy_and_upgrade_lessVars() public returns (YABTransfer_lessVars){
        YABTransfer_lessVars yab_lessVars = new YABTransfer_lessVars();
        YABTransfer_lessVars yab_lessVars_caller = YABTransfer_lessVars(address(proxy));
        yab_lessVars_caller.upgradeToAndCall(address(yab_lessVars), '');
        return yab_lessVars_caller;
    }

    function deploy_and_upgrade_reorgVars() public returns (YABTransfer_reorgVars){
        YABTransfer_reorgVars yab_reorgVars = new YABTransfer_reorgVars();
        YABTransfer_reorgVars yab_reorgVars_caller = YABTransfer_reorgVars(address(proxy));
        yab_reorgVars_caller.upgradeToAndCall(address(yab_reorgVars), '');
        return yab_reorgVars_caller;
    }

    function deploy_and_upgrade_oldVars() public returns (YABTransfer){
        YABTransfer yab_old = new YABTransfer();
        YABTransfer yab_old_caller = YABTransfer(address(proxy));
        yab_old_caller.upgradeToAndCall(address(yab_old), '');
        return yab_old_caller;
    }

    function deploy_and_upgrade_moreVars_before() public returns (YABTransfer_moreVars_before){
        YABTransfer_moreVars_before yab_moreVars_before = new YABTransfer_moreVars_before();
        YABTransfer_moreVars_before yab_moreVars_before_caller = YABTransfer_moreVars_before(address(proxy));
        yab_moreVars_before_caller.upgradeToAndCall(address(yab_moreVars_before), '');
        return yab_moreVars_before_caller;
    }

    function deploy_and_upgrade_moreVars_after() public returns (YABTransfer_moreVars_after){
        YABTransfer_moreVars_after yab_moreVars_after = new YABTransfer_moreVars_after();
        YABTransfer_moreVars_after yab_moreVars_after_caller = YABTransfer_moreVars_after(address(proxy));
        yab_moreVars_after_caller.upgradeToAndCall(address(yab_moreVars_after), '');
        return yab_moreVars_after_caller;
    }


    // function test_read_values() public { //ok
    //     assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
    //     assertEq(yab_caller.getEscrowAddress(), 0x0);
    // }

    // function test_should_fail_read_deleted_values() public { //ok?
    //     vm.startPrank(deployer);
    //     YABTransfer_lessVars yab_lessVars_caller = deploy_and_upgrade_lessVars();
    //     vm.expectRevert(); //function does not exist
    //     yab_caller.getEscrowWithdrawSelector();
    //     vm.expectRevert(); //function does not exist
    //     yab_caller.getEscrowAddress();
    //     vm.stopPrank();
    // }

    // //WARNING
    // function test_read_reorg_values() public { //this test proves reorganizing values in storage IS HIGHLY DANGEROUS
    //     vm.startPrank(deployer);
    //     assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
    //     assertEq(yab_caller.getEscrowAddress(), 0x0);

    //     YABTransfer_reorgVars yab_reorgVars_caller = deploy_and_upgrade_reorgVars();

    //     assertEq(yab_reorgVars_caller.getEscrowWithdrawSelector(), 0x0);
    //     assertEq(yab_reorgVars_caller.getEscrowAddress(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
    //     vm.stopPrank();
    // }

    // //WARNING
    // function test_read_delAndReorg_values() public {//this test proves reorganizing values in storage IS HIGHLY DANGEROUS
    //     vm.startPrank(deployer);
    //     assertEq(yab_caller.getEscrowWithdrawSelector(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
    //     assertEq(yab_caller.getEscrowAddress(), 0x0);

    //     YABTransfer_lessVars yab_lessVars_caller = deploy_and_upgrade_lessVars();
    //     YABTransfer_reorgVars yab_reorgVars_caller = deploy_and_upgrade_reorgVars();

    //     assertEq(yab_reorgVars_caller.getEscrowWithdrawSelector(), 0x0);
    //     assertEq(yab_reorgVars_caller.getEscrowAddress(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
    //     vm.stopPrank();
    // }
    

    // function test_read_var_before() public { //WIP
    //     vm.startPrank(deployer);
    //     vm.expectRevert(); //function does not exist
    //     yab_caller.getNewVarBefore();

    //     YABTransfer_moreVars_before yab_moreVars_before_caller =  ();

    //     assertEq(yab_moreVars_before_caller.getEscrowWithdrawSelector(), 0x0);
    //     assertEq(yab_moreVars_before_caller.getEscrowAddress(), 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77);
    //     vm.stopPrank();
    // }
}
