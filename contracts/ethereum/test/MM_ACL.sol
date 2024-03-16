// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/PaymentRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TransferTest is Test {
    address public deployer = makeAddr('deployer');
    address public marketMaker = makeAddr('marketMaker');
    uint256 public snEscrowAddress = 0x0;

    PaymentRegistry public yab;
    ERC1967Proxy public proxy;
    PaymentRegistry public yab_caller;

    address STARKNET_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    uint256 SN_ESCROW_CLAIM_PAYMENT_SELECTOR = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;

    function setUp() public {
        vm.startPrank(deployer);

        yab = new PaymentRegistry();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = PaymentRegistry(address(proxy));
        yab_caller.initialize(STARKNET_MESSAGING_ADDRESS, snEscrowAddress, SN_ESCROW_CLAIM_PAYMENT_SELECTOR, marketMaker);

        vm.stopPrank();
    }

    function test_getMMAddress() public {
        address mmAddress = yab_caller.getMMAddress();
        assertEq(mmAddress, marketMaker);
    }

    function test_set_and_get_MMAddress_deployer() public {
        vm.startPrank(deployer);
        address alice = makeAddr("alice");
        yab_caller.setMMAddress(alice);
        assertEq(yab_caller.getMMAddress(), alice);
        vm.stopPrank();
    }

    function test_set_MMAddress_not_owner() public {
        address bob = makeAddr("bob");
        vm.expectRevert(); //setMMAddress is only callable by the owner
        yab_caller.setMMAddress(bob);
    }

    function test_get_owner() public {
        address ownerAddress = yab_caller.owner();
        assertEq(ownerAddress, deployer);
    }
}
