// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TransferTest is Test {
    YABTransfer public yab;
    address public marketMaker;
    ERC1967Proxy public proxy;

    function setUp() public {
        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
        marketMaker = 0xda963fA72caC2A3aC01c642062fba3C099993D56;
        
        yab = new YABTransfer();
        proxy = new ERC1967Proxy(address(yab), "");
        YABTransfer(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snEscrowWithdrawSelector, marketMaker);
    }

    // Test cases are WIP

    function testTransfer() public {
        hoax(marketMaker, 100 wei);
        YABTransfer(address(proxy)).transfer{value: 100}(1, 0x1, 100);
    }
}
