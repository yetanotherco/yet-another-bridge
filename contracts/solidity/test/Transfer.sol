// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";

contract TransferTest is Test {
    YABTransfer public yab;

    function setUp() public {
        uint256 snMessagingAddress = uint256(uint160(0xde29d060D45901Fb19ED6C6e959EB22d8626708e));
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x0;
        yab = new YABTransfer();
        yab.setSnMessagingAddress(snMessagingAddress);
        yab.setSnEscrowAddress(snEscrowAddress);
        yab.setSnEscrowWithdrawSelector(snEscrowWithdrawSelector);
    }

    function testTransfer() public {
        yab.transfer{value: 100}(1, 1, 0x1, 100);
    }
}
