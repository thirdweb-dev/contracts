// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IMintFeeManager {
    function calculatePlatformFeeAndRecipient(
        uint256 _price
    ) external view returns (uint256 platformFee, address feeRecipient);
}
