// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "./../utils/BaseAccount.sol";

// Fixed Extensions
import "../../extension/Multicall.sol";
import "../../dynamic-contracts/extension/Initializable.sol";
import "../../eip/ERC1271.sol";
import "../../dynamic-contracts/extension/AccountPermissions.sol";

// Utils
import "./BaseAccountFactory.sol";
import "../non-upgradeable/Account.sol";
import "../../openzeppelin-presets/utils/cryptography/ECDSA.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract AccountCore is Initializable, Multicall, BaseAccount, ERC1271, AccountPermissions {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP 4337 factory for this contract.
    address public immutable factory;

    /// @notice EIP 4337 Entrypoint contract.
    IEntryPoint private immutable entrypointContract;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}

    constructor(IEntryPoint _entrypoint, address _factory) EIP712("Account", "1") {
        _disableInitializers();
        factory = _factory;
        entrypointContract = _entrypoint;
    }

    /// @notice Initializes the smart contract wallet.
    function initialize(address _defaultAdmin, bytes calldata) public virtual initializer {
        _setAdmin(_defaultAdmin, true);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the EIP 4337 entrypoint contract.
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return entrypointContract;
    }

    /// @notice Returns the balance of the account in Entrypoint.
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /// @notice Returns whether a signer is authorized to perform transactions using the wallet.
    function isValidSigner(address _signer, UserOperation calldata _userOp) public view virtual returns (bool) {
        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();

        // First, check if the signer is an admin.
        if (data.isAdmin[_signer]) {
            return true;
        } else {
            // If not an admin, check restrictions for the role held by the signer.
            bytes32 role = data.roleOfAccount[_signer];
            Role memory restrictions = data.roleRestriction[role];

            // Check if the role is active. If the signer has no role, this condition will revert because both start and end timestamps are `0`.
            require(
                restrictions.startTimestamp <= block.timestamp && block.timestamp < restrictions.endTimestamp,
                "Account: role not active."
            );

            // Extract the function signature from the userOp calldata and check whether the signer is attempting to call `execute` or `executeBatch`.
            bytes4 sig = getFunctionSignature(_userOp.callData);

            if (sig == Account.execute.selector) {
                // Extract the `target` and `value` arguments from the calldata for `execute`.
                (address target, uint256 value) = decodeExecuteCalldata(_userOp.callData);

                // Check if the value is within the allowed range and if the target is approved.
                require(restrictions.maxValuePerTransaction >= value, "Account: value too high.");
                require(data.approvedTargets[role].contains(target), "Account: target not approved.");
            } else if (sig == Account.executeBatch.selector) {
                // Extract the `target` and `value` array arguments from the calldata for `executeBatch`.
                (address[] memory targets, uint256[] memory values) = decodeExecuteBatchCalldata(_userOp.callData);

                // For each target+value pair, check if the value is within the allowed range and if the target is approved.
                for (uint256 i = 0; i < targets.length; i++) {
                    require(data.approvedTargets[role].contains(targets[i]), "Account: target not approved.");
                    require(restrictions.maxValuePerTransaction >= values[i], "Account: value too high.");
                }
            }

            return true;
        }
    }

    /// @notice See EIP-1271
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        address signer = _hash.recover(_signature);

        AccountPermissionsStorage.Data storage data = AccountPermissionsStorage.accountPermissionsStorage();

        // Get the role held by the recovered signer.
        bytes32 role = data.roleOfAccount[signer];
        Role memory restrictions = data.roleRestriction[role];

        // Check if the role is active. If the signer has no role, this condition will fail because both start and end timestamps are `0`.
        if (restrictions.startTimestamp <= block.timestamp && restrictions.endTimestamp < block.timestamp) {
            magicValue = MAGICVALUE;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit funds for this account in Entrypoint.
    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyAdmin {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function getFunctionSignature(bytes calldata data) internal pure returns (bytes4 functionSelector) {
        require(data.length >= 4, "Calldata too short");

        bytes4 temp;
        assembly {
            calldatacopy(0, add(32, data.offset), 4) // copy first 4 bytes from calldata to memory
            temp := mload(0) // load from memory to temp
        }

        functionSelector = temp; // take first 4 bytes as function selector
    }

    function decodeExecuteCalldata(bytes calldata data) internal pure returns (address _target, uint256 _value) {
        require(data.length >= 4 + 32 + 32, "Calldata too short");

        bytes32 rawAddress;
        bytes32 rawValue;
        assembly {
            calldatacopy(0, add(36, data.offset), 32) // Copy address bytes to memory
            rawAddress := mload(0) // Load from memory to variable

            calldatacopy(0, add(68, data.offset), 32) // Copy value bytes to memory
            rawValue := mload(0) // Load from memory to variable
        }

        return (address(uint160(uint256(rawAddress))), uint256(rawValue));
    }

    function decodeExecuteBatchCalldata(bytes calldata data)
        internal
        pure
        returns (address[] memory _targets, uint256[] memory _values)
    {
        // Check that data is long enough to contain the function selector and the offsets
        require(data.length >= 4 + 32 * 3, "Calldata too short");

        uint256 targetsOffset;
        uint256 valuesOffset;
        assembly {
            calldatacopy(0, add(36, data.offset), 32) // Copy the targetsOffset bytes to memory
            targetsOffset := mload(0) // Load from memory to targetsOffset

            calldatacopy(0, add(68, data.offset), 32) // Copy the valuesOffset bytes to memory
            valuesOffset := mload(0) // Load from memory to valuesOffset
        }

        uint256 targetsLength;
        uint256 valuesLength;
        assembly {
            calldatacopy(0, add(add(targetsOffset, 4), data.offset), 32) // Copy the targetsLength bytes to memory
            targetsLength := mload(0) // Load from memory to targetsLength

            calldatacopy(0, add(add(valuesOffset, 4), data.offset), 32) // Copy the valuesLength bytes to memory
            valuesLength := mload(0) // Load from memory to valuesLength
        }

        _targets = new address[](targetsLength);
        _values = new uint256[](valuesLength);

        for (uint256 i = 0; i < targetsLength; i++) {
            bytes32 rawAddress;
            assembly {
                calldatacopy(0, add(add(add(targetsOffset, 32), mul(i, 32)), data.offset), 32) // Copy the address bytes to memory
                rawAddress := mload(0) // Load from memory to rawAddress
            }
            _targets[i] = address(uint160(uint256(rawAddress)));
        }

        for (uint256 j = 0; j < valuesLength; j++) {
            uint256 rawValue;
            assembly {
                calldatacopy(0, add(add(add(valuesOffset, 32), mul(j, 32)), data.offset), 32) // Copy the value bytes to memory
                rawValue := mload(0) // Load from memory to rawValue
            }
            _values[j] = rawValue;
        }
    }

    /// @notice Validates the signature of a user operation.
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);

        if (!isValidSigner(signer, userOp)) return SIG_VALIDATION_FAILED;
        return 0;
    }

    /// @notice Makes the given account an admin.
    function _setAdmin(address _account, bool _isAdmin) internal virtual override {
        super._setAdmin(_account, _isAdmin);
        if (factory.code.length > 0) {
            if (_isAdmin) {
                BaseAccountFactory(factory).onSignerAdded(_account);
            } else {
                BaseAccountFactory(factory).onSignerRemoved(_account);
            }
        }
    }

    /// @notice Runs after every `changeRole` run.
    function _afterChangeRole(RoleRequest calldata _req) internal virtual override {
        if (factory.code.length > 0) {
            if (_req.action == RoleAction.GRANT) {
                BaseAccountFactory(factory).onSignerAdded(_req.target);
            } else if (_req.action == RoleAction.REVOKE) {
                BaseAccountFactory(factory).onSignerRemoved(_req.target);
            }
        }
    }
}
