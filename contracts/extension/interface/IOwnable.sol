// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's (EIP 173) `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting
 *  and reading who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic
 *  that uses information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return ownerAddr address of the owner.
    function owner() external view returns (address ownerAddr);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}
