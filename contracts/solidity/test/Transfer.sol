// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";


contract TransferTest is Test {
    YABTransfer public yab;
    address SN_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;

    function setUp() public {
        address snMessagingAddress = SN_MESSAGING_ADDRESS;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;

        yab = new YABTransfer(snMessagingAddress, snEscrowAddress, snEscrowWithdrawSelector);

        // Mock calls to Starknet Messaging contract
        vm.mockCall(
            SN_MESSAGING_ADDRESS,
            abi.encodeWithSelector(IStarknetMessaging(SN_MESSAGING_ADDRESS).sendMessageToL2.selector),
            abi.encode(0x0, 0x1)
        );

    }

    function testTransfer() public {
        yab.transfer{value: 100}(1, 0x1, 100);
    }

    function testWithdraw() public {
        yab.transfer{value: 100}(1, 0x1, 100);  
        yab.withdraw(1, 0x1, 100);
    }

    function testWithdrawOver() public {
        address alice = makeAddr("alice");
        uint256 maxInt = type(uint256).max;
        
        vm.deal(alice, maxInt);
        vm.prank(alice);

        yab.transfer{value: maxInt}(1, 0x1, maxInt);
        yab.withdraw(1, 0x1, maxInt);
    }

    function testWithdrawLow() public {
        yab.transfer{value: 1}(1, 0x1, 1);
        yab.withdraw(1, 0x1, 1);
    }
}
