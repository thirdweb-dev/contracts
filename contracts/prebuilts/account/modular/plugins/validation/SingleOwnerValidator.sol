// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../utils/UserOperation.sol";
import "../../../../../external-deps/openzeppelin/utils/cryptography/ECDSA.sol";
import "../../Interfaces/IValidator.sol";

import "../../../utils/Helpers.sol";

struct SingleOwnerValidatorStorage {
    address owner;
}

contract SingleOwnerValidator is IValidator {
    using ECDSA for bytes32;

    event OwnerUpdated(address indexed account, address indexed oldOwner, address indexed newOwner);

    mapping(address => SingleOwnerValidatorStorage) public singleOwnerValidatorStorage;

    function disable(bytes calldata) external payable override {
        delete singleOwnerValidatorStorage[msg.sender];
    }

    function enable(bytes calldata _data) external payable override {
        (address owner, ) = abi.decode(_data, (address, address));
        address prevOwner = singleOwnerValidatorStorage[msg.sender].owner;
        singleOwnerValidatorStorage[msg.sender].owner = owner;
        emit OwnerUpdated(msg.sender, prevOwner, owner);
    }

    function validateUserOp(
        UserOperation calldata _userOp,
        bytes32 _userOpHash,
        uint256
    ) external payable override returns (uint256) {
        bytes32 hash = _userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(_userOp.signature);

        if (singleOwnerValidatorStorage[msg.sender].owner != signer) {
            return 1;
        }

        return _packValidationData(ValidationData(address(0), uint48(0), type(uint48).max));
    }

    function validateSignature(bytes calldata signature, bytes32 hash) public view override returns (uint256) {
        address owner = singleOwnerValidatorStorage[msg.sender].owner;

        address signer = hash.recover(signature);

        if (owner != signer) return 1;

        return _packValidationData(ValidationData(address(0), uint48(0), type(uint48).max));
    }
}
