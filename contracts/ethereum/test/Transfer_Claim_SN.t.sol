// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PaymentRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TransferTest is Test {
    event ClaimPaymentBatch(uint256[] orderIds, address[] destAddresses, uint256[] amounts, uint128 chainId);

    address public deployer = makeAddr('deployer');
    address public marketMaker = makeAddr("marketMaker");
    uint256 public snEscrowAddress = 0x0;

    PaymentRegistry public yab;
    ERC1967Proxy public proxy;
    PaymentRegistry public yab_caller;

    address STARKNET_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    uint256 SN_ESCROW_CLAIM_PAYMENT_SELECTOR = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
    address ZKSYNC_DIAMOND_PROXY_ADDRESS = 0x2eD8eF54a16bBF721a318bd5a5C0F39Be70eaa65;

    uint128 STARKNET_CHAIN_ID = 0x534e5f5345504f4c4941;
    uint128 ZKSYNC_CHAIN_ID = 300;

    function setUp() public {
        vm.startPrank(deployer);
                
        yab = new PaymentRegistry();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = PaymentRegistry(address(proxy));
        yab_caller.initialize(STARKNET_MESSAGING_ADDRESS, snEscrowAddress, SN_ESCROW_CLAIM_PAYMENT_SELECTOR, 0x0, marketMaker, ZKSYNC_DIAMOND_PROXY_ADDRESS, STARKNET_CHAIN_ID, ZKSYNC_CHAIN_ID);

        // Mock calls to Starknet Messaging contract
        vm.mockCall(
            STARKNET_MESSAGING_ADDRESS,
            abi.encodeWithSelector(IStarknetMessaging(STARKNET_MESSAGING_ADDRESS).sendMessageToL2.selector),
            abi.encode(0x0, 0x1)
        );
        vm.stopPrank();
    }

    function test_transfer_sn() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), 0x534e5f5345504f4c4941);
        assertEq(address(0x1).balance, 100);
    }

    function test_transfer_sn_fail_already_transferred() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer already processed.");
        yab_caller.transfer{value: 100}(1, address(0x1), 0x534e5f5345504f4c4941);
    }

    function test_claimPayment_sn_fail_noOrderId() public {
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a random transfer number
        yab_caller.claimPayment{value: 100}(1, address(0x1), 100);
    }

    function test_claimPayment_sn_fail_wrongOrderId() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), 0x534e5f5345504f4c4941);  
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a wrong transfer number
        yab_caller.claimPayment(2, address(0x1), 100);
    }

    function test_claimPayment_sn() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), 0x534e5f5345504f4c4941);  
        hoax(marketMaker, 100 wei);
        yab_caller.claimPayment(1, address(0x1), 100);
        assertEq(address(marketMaker).balance, 100);
    }

    function test_claimPayment_sn_maxInt() public {
        uint256 maxInt = type(uint256).max;
        
        vm.deal(marketMaker, maxInt);
        vm.startPrank(marketMaker);

        yab_caller.transfer{value: maxInt}(1, address(0x1), 0x534e5f5345504f4c4941);
        yab_caller.claimPayment(1, address(0x1), maxInt);
        vm.stopPrank();
    }

    function test_claimPayment_sn_minInt() public {
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 1 wei);
        yab_caller.claimPayment(1, address(0x1), 1);
    }

    function testClaimPaymentBatch() public {
        hoax(marketMaker, 3 wei);
        yab_caller.transfer{value: 3}(1,address(0x1), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 2 wei);
        yab_caller.transfer{value: 2}(2, address(0x3), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(3, address(0x5), 0x534e5f5345504f4c4941);

        uint256[] memory orderIds = new uint256[](3);
        address[] memory destAddresses = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        orderIds[0] = 1;
        orderIds[1] = 2;
        orderIds[2] = 3;

        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x3);
        destAddresses[2] = address(0x5);

        amounts[0] = 3;
        amounts[1] = 2;
        amounts[2] = 1;

        hoax(marketMaker);
        vm.expectEmit(true, true, true, true);
        emit ClaimPaymentBatch(orderIds, destAddresses, amounts, 0x534e5f5345504f4c4941);
        yab_caller.claimPaymentBatch(orderIds, destAddresses, amounts);

        assertEq(address(0x1).balance, 3);
        assertEq(address(0x3).balance, 2);
        assertEq(address(0x5).balance, 1);
    }

    function testClaimPaymentBatchPartial() public {
        hoax(marketMaker, 3 wei);
        yab_caller.transfer{value: 3}(1, address(0x1), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 2 wei);
        yab_caller.transfer{value: 2}(2, address(0x3), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(3, address(0x5), 0x534e5f5345504f4c4941);

        uint256[] memory orderIds = new uint256[](2);
        address[] memory destAddresses = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        orderIds[0] = 1;
        orderIds[1] = 2;

        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x3);

        amounts[0] = 3;
        amounts[1] = 2;

        hoax(marketMaker);
        yab_caller.claimPaymentBatch(orderIds, destAddresses, amounts);

        assertEq(address(0x1).balance, 3);
        assertEq(address(0x3).balance, 2);
    }

    function testClaimPaymentBatch_fail_MissingTransfer() public {
        hoax(marketMaker, 3 wei);
        yab_caller.transfer{value: 3}(1, address(0x1), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 2 wei);
        yab_caller.transfer{value: 2}(2, address(0x3), 0x534e5f5345504f4c4941);

        uint256[] memory orderIds = new uint256[](3);
        address[] memory destAddresses = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        orderIds[0] = 1;
        orderIds[1] = 2;
        orderIds[2] = 3;

        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x3);
        destAddresses[2] = address(0x5);

        amounts[0] = 3;
        amounts[1] = 2;
        amounts[2] = 1;

        vm.expectRevert("Transfer not found.");
        hoax(marketMaker);
        yab_caller.claimPaymentBatch(orderIds, destAddresses, amounts);
    }

    function testClaimPaymentBatch_fail_notOwnerOrMM() public {
        hoax(marketMaker, 3 wei);
        yab_caller.transfer{value: 3}(1, address(0x1), 0x534e5f5345504f4c4941);

        uint256[] memory orderIds = new uint256[](1);
        address[] memory destAddresses = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        orderIds[0] = 1;

        destAddresses[0] = address(0x1);

        amounts[0] = 3;

        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.claimPaymentBatch(orderIds, destAddresses, amounts);
    }

    function test_claimPayment_fail_wrongChain() public {
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), 0x534e5f5345504f4c4941);
        hoax(marketMaker, 1 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a transfer made on the other chain
        yab_caller.claimPaymentZKSync(1, address(0x1), 1, 1 ,1);  
    }
}
