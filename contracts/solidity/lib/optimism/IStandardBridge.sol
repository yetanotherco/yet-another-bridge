// SPDX-License-Identifier: MIT
// https://github.com/ethereum-optimism/optimism/blob/master/packages/contracts-bedrock/contracts/L1/L1StandardBridge.sol
pragma solidity 0.8.21;

interface IStandardBridge {
    function bridgeETH(
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external payable;

    function bridgeETHTo(
        address _to,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external payable;

    function bridgeERC20(
        address _localToken,
        address _remoteToken,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;
}
