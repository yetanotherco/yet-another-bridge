pragma solidity ^0.8.21;

contract mock_IStarknetMessaging {
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32, uint256) {
        require(msg.value > 0, "L1_MSG_FEE_MUST_BE_GREATER_THAN_0");
        require(msg.value <= 1 ether, "MAX_L1_MSG_FEE_EXCEEDED");
        //content of contract
        return (0x0, 0x0); //mock values, unused.
    }
}