// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IAppURI.sol";

/**
 *  Thirdweb's `AppURI` is a contract extension for any contract
 *  that wants to add an official App URI that follows the appUri spec
 *
 */

abstract contract AppURI is IAppURI {
    /// @dev appURI
    string public override appURI;

    /// @dev Lets a contract admin set the URI for app metadata.
    function setAppURI(string memory _uri) public override {
        if (!_canSetAppURI()) {
            revert("Not authorized");
        }

        _setupAppURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for app metadata.
    function _setupAppURI(string memory _uri) internal {
        string memory prevURI = appURI;
        appURI = _uri;

        emit AppURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether appUri can be set in the given execution context.
    function _canSetAppURI() internal view virtual returns (bool);
}
