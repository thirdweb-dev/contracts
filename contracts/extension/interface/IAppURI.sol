// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `AppURI` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 */

interface IAppURI {
    /// @dev Returns the metadata URI of the contract.
    function appURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setAppURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event AppURIUpdated(string prevURI, string newURI);
}
