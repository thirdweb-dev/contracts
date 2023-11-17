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
import "../../../extension/upgradeable/Initializable.sol";
import "../../../extension/upgradeable/ContractMetadata.sol";
import "../../../extension/Multicall.sol";

// Utils
import "../../../eip/ERC1271.sol";
import "../utils/Helpers.sol";
import "../../../external-deps/openzeppelin/utils/cryptography/ECDSA.sol";
import "../utils/BaseAccountFactory.sol";
import "./ModularAccountStorage.sol";

import "./Interfaces/IValidator.sol";
import "./Interfaces/IModularAccount.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract ModularAccount is
    IModularAccount,
    Initializable,
    ERC1271,
    ERC721Holder,
    ERC1155Holder,
    BaseAccount,
    Multicall,
    ContractMetadata
{
    /// @notice EIP 4337 Entrypoint contract.
    IEntryPoint private immutable entrypointContract;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) {
        _disableInitializers();
        entrypointContract = _entrypoint;
    }

    function initialize(
        address _defaultAdmin,
        address _factory,
        bytes calldata _data
    ) public virtual initializer {
        ModularAccountStorage.data().factory = _factory;
        ModularAccountStorage.data().creationSalt = _generateSalt(_defaultAdmin, _data);
        (, address _validator) = abi.decode(_data, (address, address));
        ModularAccountStorage.data().validator = _validator;
        IValidator(_validator).activate(_data);
    }

    /// @notice Lets the account receive native tokens.
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice See EIP-1271
    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        public
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        ValidationData memory _validationData = _parseValidationData(validateSignature(_hash, _signature));
        if (_validationData.validAfter > block.timestamp) revert();
        if (_validationData.validUntil < block.timestamp) revert();
        if (_validationData.aggregator != address(0)) revert();

        return MAGICVALUE;
    }

    /// @notice See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function validateSignature(bytes32 hash, bytes calldata signature) public view returns (uint256 validationData) {
        return IValidator(ModularAccountStorage.data().validator).validateSignature(signature, hash);
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return entrypointContract;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a transaction (called directly from a valid caller, or by entryPoint)
    function execute(
        address _target,
        uint256 _value,
        bytes calldata _calldata
    ) external virtual {
        _onlyEntryPointOrValidCaller();
        _registerOnFactory();
        _call(_target, _value, _calldata);
    }

    /// @notice Executes a sequence transaction (called directly from a valid caller, or by entryPoint)
    function executeBatch(
        address[] calldata _target,
        uint256[] calldata _value,
        bytes[] calldata _calldata
    ) external virtual {
        _onlyEntryPointOrValidCaller();
        _registerOnFactory();

        require(_target.length == _calldata.length && _target.length == _value.length, "Account: wrong array lengths.");
        for (uint256 i = 0; i < _target.length; i++) {
            _call(_target[i], _value[i], _calldata[i]);
        }
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override(BaseAccount, IAccount) returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = IValidator(ModularAccountStorage.data().validator).validateUserOp(
            userOp,
            userOpHash,
            missingAccountFunds
        );
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    function setValidator(address _validator) external {
        if (!_validateCaller(msg.sender, msg.data)) {
            revert("not valid caller"); //add revert
        }
        ModularAccountStorage.data().validator = _validator;
    }

    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public {
        if (!_validateCaller(msg.sender, msg.data)) {
            revert(); //add revert
        }
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function factory() public view returns (address) {
        return ModularAccountStorage.data().factory;
    }

    function updateSignerOnFactory(address _signer, bool _status) external {
        _onlyValidator();
        if (_status) {
            BaseAccountFactory(factory()).onSignerAdded(_signer, ModularAccountStorage.data().creationSalt);
        } else {
            BaseAccountFactory(factory()).onSignerRemoved(_signer, ModularAccountStorage.data().creationSalt);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

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

    /// @dev Returns the salt used when deploying an Account.
    function _generateSalt(address _admin, bytes memory _data) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_admin, _data));
    }

    /// @dev Registers the account on the factory if it hasn't been registered yet.
    function _registerOnFactory() internal virtual {
        BaseAccountFactory factoryContract = BaseAccountFactory(factory());
        if (!factoryContract.isRegistered(address(this))) {
            factoryContract.onRegister(ModularAccountStorage.data().creationSalt);
        }
    }

    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {
        return IValidator(ModularAccountStorage.data().validator).validateSignature(userOp.signature, userOpHash);
    }

    function _validateCaller(address _caller, bytes calldata _data) internal view virtual returns (bool) {
        return IValidator(ModularAccountStorage.data().validator).validateCaller(_caller, _data);
    }

    function _onlyEntryPointOrValidCaller() internal view virtual {
        if (msg.sender != address(entryPoint()) && !_validateCaller(msg.sender, msg.data)) {
            revert("not entrypoint or valid caller");
        }
    }

    function _onlyValidator() internal view virtual {
        require(msg.sender == ModularAccountStorage.data().validator, "sender must be validator");
    }

    function _canSetContractURI() internal view virtual override returns (bool) {
        return _validateCaller(msg.sender, msg.data);
    }
}
