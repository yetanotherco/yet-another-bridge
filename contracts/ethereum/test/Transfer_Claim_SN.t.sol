// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PaymentRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TransferTest is Test {

    address public deployer = makeAddr('deployer');
    address public marketMaker = makeAddr("marketMaker");
    uint256 public snEscrowAddress = 0x0;

    PaymentRegistry public yab;
    ERC1967Proxy public proxy;
    PaymentRegistry public yab_caller;

    address SN_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    uint256 SN_ESCROW_CLAIM_PAYMENT_SELECTOR = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
    address ZKSYNC_DIAMOND_PROXY_ADDRESS = 0x2eD8eF54a16bBF721a318bd5a5C0F39Be70eaa65;

    function setUp() public {
        vm.startPrank(deployer);
                
        yab = new PaymentRegistry();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = PaymentRegistry(address(proxy));
        yab_caller.initialize(SN_MESSAGING_ADDRESS, snEscrowAddress, SN_ESCROW_CLAIM_PAYMENT_SELECTOR, marketMaker, ZKSYNC_DIAMOND_PROXY_ADDRESS);

        // Mock calls to Starknet Messaging contract
        vm.mockCall(
            SN_MESSAGING_ADDRESS,
            abi.encodeWithSelector(IStarknetMessaging(SN_MESSAGING_ADDRESS).sendMessageToL2.selector),
            abi.encode(0x0, 0x1)
        );
        vm.stopPrank();
    }

    function test_transfer_sn() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), PaymentRegistry.Chain.Starknet);
        assertEq(address(0x1).balance, 100);
    }

    //todo uncomment when applied keccac perf upgrade

    // function test_claimPayment_sn_fail_noOrderId() public {
    //     hoax(marketMaker, 100 wei);
    //     vm.expectRevert("Transfer not found."); //Won't match to a random transfer number
    //     yab_caller.claimPayment{value: 100}(1, 0x1, 100);
    // }
    // function test_claimPayment_sn_fail_wrongOrderId() public {
    //     hoax(marketMaker, 100 wei);
    //     yab_caller.transfer{value: 100}(1, 0x1, PaymentRegistry.Chain.Starknet);  
    //     hoax(marketMaker, 100 wei);
    //     vm.expectRevert("Transfer not found."); //Won't match to a wrong transfer number
    //     yab_caller.claimPayment(2, 0x1, 100);
    // }

    // function test_claimPayment_sn() public {
    //     hoax(marketMaker, 100 wei);
    //     yab_caller.transfer{value: 100}(1, 0x1, PaymentRegistry.Chain.Starknet);  
    //     hoax(marketMaker, 100 wei);
    //     yab_caller.claimPayment(1, 0x1, 100);
    //     assertEq(address(marketMaker).balance, 100);
    // }

    // function test_claimPayment_sn_maxInt() public {
    //     uint256 maxInt = type(uint256).max;
        
    //     vm.deal(marketMaker, maxInt);
    //     vm.startPrank(marketMaker);

    //     yab_caller.transfer{value: maxInt}(1, 0x1, PaymentRegistry.Chain.Starknet);
    //     yab_caller.claimPayment(1, 0x1, maxInt);
    //     vm.stopPrank();
    // }

    // function test_claimPayment_sn_minInt() public {
    //     hoax(marketMaker, 1 wei);
    //     yab_caller.transfer{value: 1}(1, 0x1, PaymentRegistry.Chain.Starknet);
    //     hoax(marketMaker, 1 wei);
    //     yab_caller.claimPayment(1, 0x1, 1);
    // }

    function test_claimPayment_fail_wrongChain() public {
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), PaymentRegistry.Chain.Starknet);
        hoax(marketMaker, 1 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a transfer made on the other chain
        yab_caller.claimPaymentZKSync(1, address(0x1), 1, 1 ,1);  
    }
}
