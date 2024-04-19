// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PaymentRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TransferTest is Test {
    event ClaimPaymentBatch(uint256[] orderIds, address[] destAddresses, uint256[] amounts, uint128 chainId);

    address public deployer = makeAddr('deployer');
    address public MM_ETHEREUM_WALLET_ADDRESS = makeAddr("marketMaker");

    PaymentRegistry public yab;
    ERC1967Proxy public proxy;
    PaymentRegistry public yab_caller;

    address STARKNET_MESSAGING_ADDRESS = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    uint256 STARKNET_CLAIM_PAYMENT_SELECTOR = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;
    uint256 STARKNET_CLAIM_PAYMENT_BATCH_SELECTOR = 0x0354a01e49fe07e43306a97ed84dbd5de8238c7d8ff616caa3444630cfc559e6;
    uint256 STARKNET_CLAIM_PAYMENT_ERC20_SELECTOR = 0x0091ec2842317cd03601c3f46ee8ebc9b1dc6cdbc96cb7b0873cc6360538d754;
    address ZKSYNC_DIAMOND_PROXY_ADDRESS = 0x2eD8eF54a16bBF721a318bd5a5C0F39Be70eaa65;
    bytes4 ZKSYNC_CLAIM_PAYMENT_SELECTOR = 0xa5168739;
    bytes4 ZKSYNC_CLAIM_PAYMENT_BATCH_SELECTOR = 0x156be1ae;
    bytes4 ZKSYNC_CLAIM_PAYMENT_ERC20_SELECTOR = 0xb9738dd6;

    uint128 STARKNET_CHAIN_ID = 0x534e5f5345504f4c4941;
    uint128 ZKSYNC_CHAIN_ID = 300;

    function setUp() public {
        vm.startPrank(deployer);
                
        yab = new PaymentRegistry();
        proxy = new ERC1967Proxy(address(yab), "");
        yab_caller = PaymentRegistry(address(proxy));
        yab_caller.initialize(STARKNET_MESSAGING_ADDRESS, STARKNET_CLAIM_PAYMENT_SELECTOR, STARKNET_CLAIM_PAYMENT_BATCH_SELECTOR, STARKNET_CLAIM_PAYMENT_ERC20_SELECTOR, MM_ETHEREUM_WALLET_ADDRESS, ZKSYNC_DIAMOND_PROXY_ADDRESS, ZKSYNC_CLAIM_PAYMENT_SELECTOR, ZKSYNC_CLAIM_PAYMENT_BATCH_SELECTOR, ZKSYNC_CLAIM_PAYMENT_ERC20_SELECTOR, STARKNET_CHAIN_ID, ZKSYNC_CHAIN_ID);
        // Mock calls to Starknet Messaging contract
        vm.mockCall(
            STARKNET_MESSAGING_ADDRESS,
            abi.encodeWithSelector(IStarknetMessaging(STARKNET_MESSAGING_ADDRESS).sendMessageToL2.selector),
            abi.encode(0x0, 0x1)
        );
        vm.stopPrank();
    }

    function test_transfer_sn() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), STARKNET_CHAIN_ID);
        assertEq(address(0x1).balance, 100);
    }

    function test_transfer_sn_fail_already_transferred() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        vm.expectRevert("Transfer already processed.");
        yab_caller.transfer{value: 100}(1, address(0x1), STARKNET_CHAIN_ID);
    }

    function test_claimPayment_sn_fail_noOrderId() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a random transfer number
        yab_caller.claimPaymentStarknet{value: 100}(1, address(0x1), 100);
    }

    function test_claimPayment_sn_fail_wrongOrderId() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), STARKNET_CHAIN_ID);  
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a wrong transfer number
        yab_caller.claimPaymentStarknet(2, address(0x1), 100);
    }

    function test_claimPayment_sn() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        yab_caller.transfer{value: 100}(1, address(0x1), STARKNET_CHAIN_ID);  
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 100 wei);
        yab_caller.claimPaymentStarknet(1, address(0x1), 100);
        assertEq(address(MM_ETHEREUM_WALLET_ADDRESS).balance, 100);
    }

    function test_claimPayment_sn_maxInt() public {
        uint256 maxInt = type(uint256).max;
        
        vm.deal(MM_ETHEREUM_WALLET_ADDRESS, maxInt);
        vm.startPrank(MM_ETHEREUM_WALLET_ADDRESS);

        yab_caller.transfer{value: maxInt}(1, address(0x1), STARKNET_CHAIN_ID);
        yab_caller.claimPaymentStarknet(1, address(0x1), maxInt);
        vm.stopPrank();
    }

    function test_claimPayment_sn_minInt() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 1 wei);
        yab_caller.claimPaymentStarknet(1, address(0x1), 1);
    }

    function testClaimPaymentBatch_sn() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 3 wei);
        yab_caller.transfer{value: 3}(1,address(0x1), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 2 wei);
        yab_caller.transfer{value: 2}(2, address(0x3), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 1 wei);
        yab_caller.transfer{value: 1}(3, address(0x5), STARKNET_CHAIN_ID);

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

        hoax(MM_ETHEREUM_WALLET_ADDRESS);
        vm.expectEmit(true, true, true, true);
        emit ClaimPaymentBatch(orderIds, destAddresses, amounts, STARKNET_CHAIN_ID);
        yab_caller.claimPaymentBatchStarknet(orderIds, destAddresses, amounts);

        assertEq(address(0x1).balance, 3);
        assertEq(address(0x3).balance, 2);
        assertEq(address(0x5).balance, 1);
    }

    function testClaimPaymentBatchPartial_sn() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 3 wei);
        yab_caller.transfer{value: 3}(1, address(0x1), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 2 wei);
        yab_caller.transfer{value: 2}(2, address(0x3), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 1 wei);
        yab_caller.transfer{value: 1}(3, address(0x5), STARKNET_CHAIN_ID);

        uint256[] memory orderIds = new uint256[](2);
        address[] memory destAddresses = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        orderIds[0] = 1;
        orderIds[1] = 2;

        destAddresses[0] = address(0x1);
        destAddresses[1] = address(0x3);

        amounts[0] = 3;
        amounts[1] = 2;

        hoax(MM_ETHEREUM_WALLET_ADDRESS);
        yab_caller.claimPaymentBatchStarknet(orderIds, destAddresses, amounts);

        assertEq(address(0x1).balance, 3);
        assertEq(address(0x3).balance, 2);
    }

    function testClaimPaymentBatch_fail_MissingTransfer() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 3 wei);
        yab_caller.transfer{value: 3}(1, address(0x1), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 2 wei);
        yab_caller.transfer{value: 2}(2, address(0x3), STARKNET_CHAIN_ID);

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
        hoax(MM_ETHEREUM_WALLET_ADDRESS);
        yab_caller.claimPaymentBatchStarknet(orderIds, destAddresses, amounts);
    }

    function testClaimPaymentBatch_fail_notOwnerOrMM() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 3 wei);
        yab_caller.transfer{value: 3}(1, address(0x1), STARKNET_CHAIN_ID);

        uint256[] memory orderIds = new uint256[](1);
        address[] memory destAddresses = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        orderIds[0] = 1;

        destAddresses[0] = address(0x1);

        amounts[0] = 3;

        hoax(makeAddr("bob"), 100 wei);
        vm.expectRevert("Only Owner or MM can call this function");
        yab_caller.claimPaymentBatchStarknet(orderIds, destAddresses, amounts);
    }

    function test_claimPayment_fail_wrongChain() public {
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 1 wei);
        yab_caller.transfer{value: 1}(1, address(0x1), STARKNET_CHAIN_ID);
        hoax(MM_ETHEREUM_WALLET_ADDRESS, 1 wei);
        vm.expectRevert("Transfer not found."); //Won't match to a transfer made on the other chain
        yab_caller.claimPaymentZKSync(1, address(0x1), 1, 1 ,1);  
    }
}
