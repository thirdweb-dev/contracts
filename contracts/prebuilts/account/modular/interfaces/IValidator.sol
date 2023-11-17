// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/UserOperation.sol";

interface IValidator {
    function activate(bytes calldata _data) external payable;

    function deactivate(bytes calldata _data) external payable;

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external payable returns (uint256);

    function validateSignature(bytes calldata signature, bytes32 hash) external view returns (uint256);

    function validateCaller(address caller, bytes calldata data) external view returns (bool);
}
