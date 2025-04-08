// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

contract MockMintFeeManager {
    address public feeRecipient;
    uint256 public feeBps;

    constructor(address _feeRecipient, uint256 _feeBps) {
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
    }

    function calculatePlatformFeeAndRecipient(
        uint256 _price
    ) external view returns (uint256 _platformFee, address _feeRecipient) {
        _platformFee = (_price * feeBps) / 10_000;
        _feeRecipient = feeRecipient;
    }
}
