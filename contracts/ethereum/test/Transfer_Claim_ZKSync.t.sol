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

    uint128 STARKNET_CHAIN_ID = 0x534e5f5345504f4c4941;
    uint128 ZKSYNC_CHAIN_ID = 300;

    function setUp() public {
        vm.startPrank(deployer);
                
        yab = new PaymentRegistry();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = PaymentRegistry(address(proxy));
        yab_caller.initialize(SN_MESSAGING_ADDRESS, snEscrowAddress, SN_ESCROW_CLAIM_PAYMENT_SELECTOR, 0x0, marketMaker, ZKSYNC_DIAMOND_PROXY_ADDRESS, STARKNET_CHAIN_ID, ZKSYNC_CHAIN_ID);

        //Mock calls to ZKSync Mailbox contract
        vm.mockCall(
            ZKSYNC_DIAMOND_PROXY_ADDRESS,
            abi.encodeWithSelector(0xeb672419, 0), //TODO add selector
            abi.encode(0x12345678901234567890123456789012) //TODO add return data
        );

        vm.stopPrank();
    }

    function test_transfer_zk() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);
        assertEq(address(0x1).balance, 100);
    }

    function test_transfer_zk_fail_already_transferred() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer already processed.");
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);
    }

    function test_claimPayment_zk_fail_noOrderId() public {
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a random transfer number
        yab_caller.claimPaymentZKSync(1, address(0x1), 100, 1, 1);
    }

    function test_claimPayment_zk_fail_wrongOrderId() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);  
        hoax(marketMaker, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a wrong transfer number
        yab_caller.claimPaymentZKSync(2, address(0x1), 100, 1, 1);
    }

    function test_claimPayment_zk() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);  
        hoax(marketMaker, 100 wei);
        yab_caller.claimPaymentZKSync(1, address(0x1), 100, 1, 1);
        assertEq(address(marketMaker).balance, 100);
    }

    function test_claimPaymentBatch_zk() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);  
        hoax(marketMaker, 101 wei);
        yab_caller.transfer{value: 100}(2, address(0x1), ZKSYNC_CHAIN_ID);  

        uint256[] memory orderIds = new uint256[](2);
        address[] memory destAddresses = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        orderIds[0] = 1;
        orderIds[1] = 2;
        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x1);
        amounts[0] = 100;
        amounts[1] = 100;

        vm.mockCall(
            ZKSYNC_DIAMOND_PROXY_ADDRESS,
            abi.encodeWithSelector(0x156be1ae, 0), //TODO add selector
            abi.encode(0x12345678901234567890123456789012) //TODO add return data
        );
        hoax(marketMaker);
        yab_caller.claimPaymentBatchZKSync(orderIds, destAddresses, amounts, 1, 1);
    }

    function test_claimPaymentBatch_zk_fail_MissingTransfer() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);  

        uint256[] memory orderIds = new uint256[](2);
        address[] memory destAddresses = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        orderIds[0] = 1;
        orderIds[1] = 2;
        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x1);
        amounts[0] = 100;
        amounts[1] = 100;

        vm.expectRevert("Transfer not found.");
        hoax(marketMaker);
        yab_caller.claimPaymentBatchZKSync(orderIds, destAddresses, amounts, 1, 1);
    }

    function test_claimPaymentBatch_zk_fail_notOwnerOrMM() public {
        hoax(marketMaker, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), ZKSYNC_CHAIN_ID);  

        uint256[] memory orderIds = new uint256[](2);
        address[] memory destAddresses = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        orderIds[0] = 1;
        orderIds[1] = 2;
        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x1);
        amounts[0] = 100;
        amounts[1] = 100;

        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.claimPaymentBatchZKSync(orderIds, destAddresses, amounts, 0, 1);
    }

    function test_claimPayment_zk_maxInt() public {
        uint256 maxInt = type(uint256).max;
        
        vm.deal(marketMaker, maxInt);
        vm.startPrank(marketMaker);

        yab_caller.transfer{value: maxInt}(1, address(0x1), ZKSYNC_CHAIN_ID);
        yab_caller.claimPaymentZKSync(1, address(0x1), maxInt, 1, 1);
        vm.stopPrank();
    }

    function test_claimPayment_zk_minInt() public {
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), ZKSYNC_CHAIN_ID);
        hoax(marketMaker, 1 wei);
        yab_caller.claimPaymentZKSync(1, address(0x1), 1, 1, 1);
    }

    function test_claimPayment_fail_wrongChain() public {
        hoax(marketMaker, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), ZKSYNC_CHAIN_ID);
        hoax(marketMaker, 1 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a transfer made on the other chain
        yab_caller.claimPayment(1, address(0x1), 1);  
    }
}
