// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

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

    address SN_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    uint256 SN_ESCROW_CLAIM_PAYMENT_SELECTOR = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
    address ZKSYNC_DIAMOND_PROXY_ADDRESS = 0x2eD8eF54a16bBF721a318bd5a5C0F39Be70eaa65;

    uint128 STARKNET_CHAIN_ID = 0x534e5f5345504f4c4941;
    uint128 ZKSYNC_CHAIN_ID = 300;

    function setUp() public {
        vm.startPrank(deployer);

        yab = new PaymentRegistry();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = PaymentRegistry(address(proxy));
        yab_caller.initialize(SN_MESSAGING_ADDRESS, snEscrowAddress, SN_ESCROW_CLAIM_PAYMENT_SELECTOR, 0x0, marketMaker, ZKSYNC_DIAMOND_PROXY_ADDRESS, STARKNET_CHAIN_ID, ZKSYNC_CHAIN_ID);

        vm.stopPrank();
    }

    function test_getMarketMaker() public {
        address mmAddress = yab_caller.marketMaker();
        assertEq(mmAddress, marketMaker);
    }

    function test_set_and_get_MMAddress_deployer() public {
        vm.startPrank(deployer);
        address alice = makeAddr("alice");
        yab_caller.setMMAddress(alice);
        assertEq(yab_caller.marketMaker(), alice);
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

    function test_transfer_sn_fail_notOwnerOrMM() public {
        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.transfer{value: 100}(1, address(0x1), STARKNET_CHAIN_ID);
    }

    function test_claimPayment_sn_fail_notOwnerOrMM() public {
        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.claimPayment{value: 100}(1, address(0x1), 100);
    }

    function test_transfer_zk_fail_notOwnerOrMM() public {
        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);
    }

    function test_claimPayment_zk_fail_notOwnerOrMM() public {
        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.claimPaymentZKSync{value: 100}(1, address(0x1), 100, 1, 1);
    }

    function test_setStarknetClaimPaymentSelector() public {
        vm.startPrank(deployer);
        yab_caller.setStarknetClaimPaymentSelector(0x123);
    }

    function test_setStarknetClaimPaymentSelector_fail_notOwnerOrMM() public {
        hoax(makeAddr("alice"), 100 wei);
        vm.expectRevert(); //only owner
        yab_caller.setStarknetClaimPaymentSelector(0x123);
    }

    function test_set_and_get_StarknetClaimPaymentSelector() public {
        vm.startPrank(deployer);
        uint256 new_selector = 0x123;
        yab_caller.setStarknetClaimPaymentSelector(new_selector);
        assertEq(yab_caller.StarknetEscrowClaimPaymentSelector(), new_selector);
        vm.stopPrank();
    }

    function test_setStarknetEscrowAddress() public {
        vm.startPrank(deployer);
        yab_caller.setStarknetEscrowAddress(0x123);
    }

    function test_setStarknetEscrowAddress_fail_notOwnerOrMM() public {
        hoax(makeAddr("alice"), 100 wei);
        vm.expectRevert(); //only owner
        yab_caller.setStarknetEscrowAddress(0x123);
    }

    function test_set_and_get_StarknetEscrowAddress() public {
        vm.startPrank(deployer);
        uint256 new_addr = 0x123;
        yab_caller.setStarknetEscrowAddress(new_addr);
        assertEq(yab_caller.StarknetEscrowAddress(), new_addr);
        vm.stopPrank();
    }

    function test_setZKSyncEscrowAddress() public {
        vm.startPrank(deployer);
        yab_caller.setZKSyncEscrowAddress(makeAddr("escrow"));
    }

    function test_setZKSyncEscrowAddress_fail_notOwnerOrMM() public {
        hoax(makeAddr("alice"), 100 wei);
        vm.expectRevert(); //only owner
        yab_caller.setZKSyncEscrowAddress(makeAddr("alice"));
    }

    function test_set_and_get_ZKSyncEscrowAddress() public {
        vm.startPrank(deployer);
        address new_addr = makeAddr("new_addr");
        yab_caller.setZKSyncEscrowAddress(new_addr);
        assertEq(yab_caller.ZKSyncEscrowAddress(), new_addr);
        vm.stopPrank();
    }
}
