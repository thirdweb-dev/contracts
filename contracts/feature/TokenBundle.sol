// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ITokenBundle.sol";

abstract contract TokenBundle is ITokenBundle {
    mapping(uint256 => BundleInfo) private bundle;

    // function _getNextBundleId() internal virtual returns (uint256);

    function getTokenCount(uint256 _bundleId) public view returns (uint256) {
        return bundle[_bundleId].count;
    }

    function getToken(uint256 _bundleId, uint256 index) public view returns (Token memory) {
        return bundle[_bundleId].tokens[index];
    }

    function getUri(uint256 _bundleId) public view returns (string memory) {
        return bundle[_bundleId].uri;
    }

    function _setBundle(Token[] calldata _tokensToBind, uint256 _bundleId) internal {
        // uint256 _bundleId = _getNextBundleId();
        require(_tokensToBind.length > 0, "no tokens to bind");
        for (uint256 i = 0; i < _tokensToBind.length; i += 1) {
            bundle[_bundleId].tokens[i] = _tokensToBind[i];
        }
        bundle[_bundleId].count = _tokensToBind.length;
    }

    function _setBundleToken(
        Token memory _tokenToBind,
        uint256 _bundleId,
        uint256 index,
        bool isUpdate
    ) internal {
        bundle[_bundleId].tokens[index] = _tokenToBind;
        bundle[_bundleId].count += isUpdate ? 0 : 1;
    }

    function _setUri(string calldata _uri, uint256 _bundleId) internal {
        bundle[_bundleId].uri = _uri;
    }

    function _deleteBundle(uint256 _bundleId) internal {
        delete bundle[_bundleId];
    }
}
