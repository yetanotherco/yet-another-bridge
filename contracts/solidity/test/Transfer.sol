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

    function testTransfer_mm() public { //ok
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, 0x1, 100);
    }

    function testTransfer_fail() public { //ok
        hoax(address(0x0000000000000000000000000000000000000001), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.transfer{value: 100}(1, 0x1, 100);
    }

    // function testWithdraw_mm() public {
    //     hoax(marketMaker, 100 wei);
    //     yab_caller.transfer{value: 100}(1, 0x1, 100);
    //     hoax(marketMaker, 100 wei);
    //     yab_caller.withdraw{value: 100}(1, 0x1, 100);
    // }

    function testWithdraw_mm_fail() public { //ok
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a random transfer number
        yab_caller.withdraw{value: 100}(1, 0x1, 100);
    }

    function testWithdraw_fail() public { //ok
        hoax(0x0000000000000000000000000000000000000001, 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.withdraw{value: 100}(1, 0x1, 100);
    }
}
