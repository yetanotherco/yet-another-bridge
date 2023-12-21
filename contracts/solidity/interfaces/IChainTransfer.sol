// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

interface IChainTransfer {
    function transfer(
        uint256 destAddress,
        uint256 amount
    ) external payable;

    function withdraw(
        uint256[] calldata payload
    ) external payable;
}
