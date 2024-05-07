// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { OwnableStorage } from "../Ownable.sol";

contract OwnableInit {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        OwnableStorage.Data storage data = OwnableStorage.data();

        address _prevOwner = data._owner;
        data._owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }
}
