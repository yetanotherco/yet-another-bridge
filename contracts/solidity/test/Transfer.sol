// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract TransferTest is Test {
    address public deployer = address(0xB321099cf86D9BB913b891441B014c03a6CcFc54);
    address public marketMaker = makeAddr("marketMaker");
    uint256 public snEscrowAddress = 0x0;

    YABTransfer public yab;
    
    ERC1967Proxy public proxy;
    YABTransfer public yab_caller;

    address SN_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    uint256 SN_ESCROW_WITHDRAW_SELECTOR = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;

    function setUp() public {
        vm.startPrank(deployer);
                
        yab = new YABTransfer();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = YABTransfer(address(proxy));
        yab_caller.initialize(SN_MESSAGING_ADDRESS, snEscrowAddress, SN_ESCROW_WITHDRAW_SELECTOR, marketMaker);

        // Mock calls to Starknet Messaging contract
        vm.mockCall(
            SN_MESSAGING_ADDRESS,
            abi.encodeWithSelector(IStarknetMessaging(SN_MESSAGING_ADDRESS).sendMessageToL2.selector),
            abi.encode(0x0, 0x1)
        );
        vm.stopPrank();
    }

    function testTransfer_mm() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, 0x1, 100);
    }

    function testTransfer_fail_notOwnerOrMM() public {
        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.transfer{value: 100}(1, 0x1, 100);
    }

    function testWithdraw_mm() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, 0x1, 100);

        hoax(marketMaker, 100 wei);
        yab_caller.withdraw{value: 100}(1, 0x1, 100);
    }

    function testWithdraw_fail_noOrderId() public {
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a random transfer number
        yab_caller.withdraw{value: 100}(1, 0x1, 100);
    }

    function testWithdraw_fail_notOwnerOrMM() public {
        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.withdraw{value: 100}(1, 0x1, 100);
    }

    function testWithdraw() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, 0x1, 100);  
        hoax(marketMaker, 100 wei);
        yab_caller.withdraw(1, 0x1, 100);
    }

    function testWithdrawOver() public {
        uint256 maxInt = type(uint256).max;
        
        vm.deal(marketMaker, maxInt);
        vm.startPrank(marketMaker);

        yab_caller.transfer{value: maxInt}(1, 0x1, maxInt);
        yab_caller.withdraw(1, 0x1, maxInt);
        vm.stopPrank();
    }

    function testWithdrawLow() public {
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(1, 0x1, 1);
        hoax(marketMaker, 1 wei);
        yab_caller.withdraw(1, 0x1, 1);
    }
}
