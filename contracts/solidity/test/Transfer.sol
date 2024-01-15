// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";

contract TransferTest is Test {
    YABTransfer public yab;

    function setUp() public {
        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
        yab = new YABTransfer();
        yab.initialize(snMessagingAddress, snEscrowAddress, snEscrowWithdrawSelector);
    }

    function testTransfer() public {
        yab.transfer{value: 100}(1, 0x1, 100);
    }
}
