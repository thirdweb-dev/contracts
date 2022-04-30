// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IThirdwebOwnable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract Ownable is IThirdwebOwnable, AccessControlEnumerableUpgradeable {

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Returns the address of the current owner.
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }
}