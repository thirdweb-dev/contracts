// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ITokenBundle.sol";

abstract contract TokenBundle is ITokenBundle {
    /// @dev UID => asset count, bundle uri, and tokens contained in the bundle
    mapping(uint256 => BundleInfo) private bundle;

    /// @dev Returns the count of assets in a bundle, given a bundle Id.
    function getTokenCount(uint256 _bundleId) public view returns (uint256) {
        return bundle[_bundleId].count;
    }

    /// @dev Returns a token contained in a bundle, given a bundle Id and index of token.
    function getToken(uint256 _bundleId, uint256 index) public view returns (Token memory) {
        return bundle[_bundleId].tokens[index];
    }

    /// @dev Returns the uri of bundle for a particular bundle Id.
    function getUri(uint256 _bundleId) public view returns (string memory) {
        return bundle[_bundleId].uri;
    }

    /// @dev Lets the calling contract create/update a bundle, by passing in a list of tokens and a unique id.
    function _setBundle(Token[] calldata _tokensToBind, uint256 _bundleId) internal {
        // uint256 _bundleId = _getNextBundleId();
        require(_tokensToBind.length > 0, "no tokens to bind");
        for (uint256 i = 0; i < _tokensToBind.length; i += 1) {
            bundle[_bundleId].tokens[i] = _tokensToBind[i];
        }
        bundle[_bundleId].count = _tokensToBind.length;
    }

    /// @dev Lets the calling contract set/update a token in a bundle for a unique bundle id and index.
    function _setBundleToken(
        Token memory _tokenToBind,
        uint256 _bundleId,
        uint256 index,
        bool isUpdate
    ) internal {
        bundle[_bundleId].tokens[index] = _tokenToBind;
        bundle[_bundleId].count += isUpdate ? 0 : 1;
    }

    /// @dev Lets the calling contract set/update the bundle uri for a particular bundle id.
    function _setUri(string calldata _uri, uint256 _bundleId) internal {
        bundle[_bundleId].uri = _uri;
    }

    /// @dev Lets the calling contract delete a bundle with a given id.
    function _deleteBundle(uint256 _bundleId) internal {
        delete bundle[_bundleId];
    }
}
