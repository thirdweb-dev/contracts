// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

library OwnableStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant OWNABLE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("ownable.storage")) - 1)) & ~bytes32(uint256(0xff));

    struct Data {
        /// @dev Owner of the contract (purpose: OpenSea compatibility)
        address _owner;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = OWNABLE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract Ownable is IOwnable {
    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _ownableStorage()._owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _ownableStorage()._owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _ownableStorage()._owner;
        _ownableStorage()._owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns the Ownable storage.
    function _ownableStorage() internal pure returns (OwnableStorage.Data storage data) {
        data = OwnableStorage.data();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}
