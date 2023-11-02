// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/UserOperation.sol";

interface IValidator {
    error NotImplemented();

    function enable(bytes calldata _data) external payable;

    function disable(bytes calldata _data) external payable;

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external payable returns (uint256);

    function validateSignature(bytes calldata signature, bytes32 hash) external view returns (uint256);
}
