// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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
        marketMaker = vm.envAddress("MM_ETHEREUM_WALLET");
        
        yab = new YABTransfer();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = YABTransfer(address(proxy));
        yab_caller.initialize(snMessagingAddress, snEscrowAddress, snEscrowWithdrawSelector, marketMaker);

        vm.stopPrank();
    }

    function test_getMMAddress_deployer() public { //OK
        vm.prank(deployer);
        address MMaddress = yab_caller.getMMAddress();
        assertEq(MMaddress, vm.envAddress("MM_ETHEREUM_WALLET"));
    }

    function test_getMMAddress_mm() public { //OK
        vm.prank(marketMaker);
        address MMaddress = yab_caller.getMMAddress();
        assertEq(MMaddress, vm.envAddress("MM_ETHEREUM_WALLET"));
    }

    function test_getMMAddress_mm_fail() public { //OK
        vm.expectRevert(); //getMMAddress is only callable by owner or MM
        address MMaddress = yab_caller.getMMAddress();
    }

    function test_set_and_get_MMAddress_deployer() public { //OK
        vm.startPrank(deployer);
        address newAddress = 0x0000000000000000000000000000000000000001;
        yab_caller.setMMAddress(newAddress);
        assertEq(yab_caller.getMMAddress(), newAddress);
        vm.stopPrank();
    }

    function test_set_MMAddress_fail() public { //OK
        address newAddress = 0xda963fA72caC2A3aC01c642062fba3C099993D56;
        vm.expectRevert(); //setMMAddress is only callable by the owner
        yab_caller.setMMAddress(newAddress);
    }

    function test_get_owner() public { //OK
        address ownerAddress = yab_caller.getOwner();
        assertEq(ownerAddress, deployer);
    }
}
