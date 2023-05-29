// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

library OwnableStorage {
    bytes32 public constant OWNABLE_STORAGE_POSITION = keccak256("ownable.storage");

    struct Data {
        /// @dev Owner of the contract (purpose: OpenSea compatibility)
        address _owner;
    }

    function ownableStorage() internal pure returns (Data storage ownableData) {
        bytes32 position = OWNABLE_STORAGE_POSITION;
        assembly {
            ownableData.slot := position
        }
    }
}

abstract contract Ownable is IOwnable {
    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        OwnableStorage.Data storage data = OwnableStorage.ownableStorage();
        if (msg.sender != data._owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        OwnableStorage.Data storage data = OwnableStorage.ownableStorage();
        return data._owner;
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
        OwnableStorage.Data storage data = OwnableStorage.ownableStorage();

        address _prevOwner = data._owner;
        data._owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}
