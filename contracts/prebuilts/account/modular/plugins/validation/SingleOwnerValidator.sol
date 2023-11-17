// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../utils/UserOperation.sol";
import "../../../../../external-deps/openzeppelin/utils/cryptography/ECDSA.sol";
import "../../Interfaces/IValidator.sol";
import "../../../utils/Helpers.sol";
import "../../interfaces/IModularAccount.sol";

library SingleOwnerValidatorStorage {
    /// @custom:storage-location erc7201:single.owner.validator.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("single.owner.validator.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant SINGLE_OWNER_VALIDATOR_STORAGE_POSITION =
        0xaf195a59902847d4a0aaedbe0f074e12c4ddcb98a2c64578c15adc5c7fb3de00;

    struct Data {
        mapping(address => address) owner;
    }

    function data() internal pure returns (Data storage singleOwnerValidatorData) {
        bytes32 position = SINGLE_OWNER_VALIDATOR_STORAGE_POSITION;
        assembly {
            singleOwnerValidatorData.slot := position
        }
    }
}

contract SingleOwnerValidator is IValidator {
    using ECDSA for bytes32;

    event OwnerUpdated(address indexed account, address indexed oldOwner, address indexed newOwner);

    function deactivate(bytes calldata) external payable override {
        delete SingleOwnerValidatorStorage.data().owner[msg.sender];
    }

    function activate(bytes calldata _data) external payable override {
        (address owner, ) = abi.decode(_data, (address, address));
        address prevOwner = SingleOwnerValidatorStorage.data().owner[msg.sender];
        SingleOwnerValidatorStorage.data().owner[msg.sender] = owner;
        IModularAccount(msg.sender).updateSignerOnFactory(owner, true);
        emit OwnerUpdated(msg.sender, prevOwner, owner);
    }

    function validateUserOp(
        UserOperation calldata _userOp,
        bytes32 _userOpHash,
        uint256
    ) external payable override returns (uint256) {
        bytes32 hash = _userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(_userOp.signature);

        if (SingleOwnerValidatorStorage.data().owner[msg.sender] != signer) {
            return 1;
        }

        return _packValidationData(ValidationData(address(0), uint48(0), type(uint48).max));
    }

    function validateSignature(bytes calldata signature, bytes32 hash) public view override returns (uint256) {
        address owner = SingleOwnerValidatorStorage.data().owner[msg.sender];

        address signer = hash.recover(signature);

        if (owner != signer) return 1;

        return _packValidationData(ValidationData(address(0), uint48(0), type(uint48).max));
    }

    function validateCaller(address caller, bytes calldata) external view override returns (bool) {
        return SingleOwnerValidatorStorage.data().owner[msg.sender] == caller;
    }

    function updateOwner(address _newOwner) external {
        address prevOwner = SingleOwnerValidatorStorage.data().owner[msg.sender];
        SingleOwnerValidatorStorage.data().owner[msg.sender] = _newOwner;
        IModularAccount(msg.sender).updateSignerOnFactory(_newOwner, true);
        IModularAccount(msg.sender).updateSignerOnFactory(prevOwner, false);
        emit OwnerUpdated(msg.sender, prevOwner, _newOwner);
    }
}
