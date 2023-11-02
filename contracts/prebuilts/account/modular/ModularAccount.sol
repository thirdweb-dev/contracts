// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "../utils/BaseAccount.sol";

// Extensions
import "../../../external-deps/openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import "../../../external-deps/openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";
import "../../../extension/Initializable.sol";

// Utils
import "../../../eip/ERC1271.sol";
import "../utils/Helpers.sol";
import "../../../external-deps/openzeppelin/utils/cryptography/ECDSA.sol";

import "./Interfaces/IValidator.sol";

import "forge-std/console.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract ModularAccount is Initializable, ERC1271, ERC721Holder, ERC1155Holder, BaseAccount {
    using ECDSA for bytes32;

    address public factory;
    IEntryPoint public immutable entrypointcontract;
    IValidator public validator;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) {
        _disableInitializers();
        entrypointcontract = _entrypoint;
    }

    function initialize(address /*_defaultAdmin*/, address _factory, bytes calldata _data) public virtual initializer {
        factory = _factory;
        (, address _validator) = abi.decode(_data, (address, address));
        validator = IValidator(_validator);
        validator.enable(_data);
    }

    /// @notice Lets the account receive native tokens.
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice See EIP-1271
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) public view virtual override returns (bytes4 magicValue) {
        ValidationData memory _validationData = _parseValidationData(validateSignature(_hash, _signature));
        if (_validationData.validAfter > block.timestamp) revert();
        if (_validationData.validUntil < block.timestamp) revert();
        if (_validationData.aggregator != address(0)) revert();

        return MAGICVALUE;
    }

    function validateSignature(bytes32 hash, bytes calldata signature) public view returns (uint256 validationData) {
        return _validateSignature(hash, signature);
    }

    function _validateSignature(bytes32 _hash, bytes calldata _signature) internal view virtual returns (uint256) {
        return IValidator(validator).validateSignature(_signature, _hash);
    }

    function _validCaller(address _caller, bytes calldata _data) internal view virtual returns (bool) {
        return IValidator(validator).validCaller(_caller, _data);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a transaction (called directly from an admin, or by entryPoint)
    function execute(address _target, uint256 _value, bytes calldata _calldata) external virtual {
        _onlyEntryPointOrValidCaller();
        _call(_target, _value, _calldata);
    }

    /// @notice Executes a sequence transaction (called directly from an admin, or by entryPoint)
    function executeBatch(
        address[] calldata _target,
        uint256[] calldata _value,
        bytes[] calldata _calldata
    ) external virtual {
        _onlyEntryPointOrValidCaller();

        require(_target.length == _calldata.length && _target.length == _value.length, "Account: wrong array lengths.");
        for (uint256 i = 0; i < _target.length; i++) {
            _call(_target[i], _value[i], _calldata[i]);
        }
    }

    function _onlyEntryPointOrValidCaller() internal view virtual {
        if (msg.sender != address(entryPoint()) || !_validCaller(msg.sender, msg.data)) {
            revert(); //add revert
        }
    }

    function setValidator(IValidator _validator) external virtual {
        if (!_validCaller(msg.sender, msg.data)) {
            revert(); //add revert
        }
        validator = _validator;
    }

    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public {
        if (!_validCaller(msg.sender, msg.data)) {
            revert(); //add revert
        }
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Registers the account on the factory if it hasn't been registered yet.

    /// @dev Calls a target contract and reverts if it fails.
    function _call(
        address _target,
        uint256 value,
        bytes memory _calldata
    ) internal virtual returns (bytes memory result) {
        bool success;
        (success, result) = _target.call{ value: value }(_calldata);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return entrypointcontract;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateUserOp(userOp, userOpHash, missingAccountFunds);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    function _validateSignature(
        bytes memory signature,
        bytes32 hash
    ) internal virtual returns (uint256 validationData) {
        return validator.validateSignature(signature, hash);
    }

    function _validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) internal virtual returns (uint256 validationData) {
        return validator.validateUserOp(userOp, userOpHash, missingAccountFunds);
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        return validator.validateSignature(userOp.signature, userOpHash);
    }
}
