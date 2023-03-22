// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/ITokenBundle.sol";
import "../../lib/CurrencyTransferLib.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

library TokenBundleStorage {
    bytes32 public constant TOKEN_BUNDLE_STORAGE_POSITION = keccak256("token.bundle.storage");

    struct Data {
        /// @dev Mapping from bundle UID => bundle info.
        mapping(uint256 => ITokenBundle.BundleInfo) bundle;
    }

    function tokenBundleStorage() internal pure returns (Data storage tokenBundleData) {
        bytes32 position = TOKEN_BUNDLE_STORAGE_POSITION;
        assembly {
            tokenBundleData.slot := position
        }
    }
}

/**
 *  @title   Token Bundle
 *  @notice  `TokenBundle` contract extension allows bundling-up of ERC20/ERC721/ERC1155 and native-tokan assets
 *           in a data structure, and provides logic for setting/getting IDs and URIs for created bundles.
 *  @dev     See {ITokenBundle}
 */

abstract contract TokenBundle is ITokenBundle {
    /// @dev Returns the total number of assets in a particular bundle.
    function getTokenCountOfBundle(uint256 _bundleId) public view returns (uint256) {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        return data.bundle[_bundleId].count;
    }

    /// @dev Returns an asset contained in a particular bundle, at a particular index.
    function getTokenOfBundle(uint256 _bundleId, uint256 index) public view returns (Token memory) {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        return data.bundle[_bundleId].tokens[index];
    }

    /// @dev Returns the uri of a particular bundle.
    function getUriOfBundle(uint256 _bundleId) public view returns (string memory) {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        return data.bundle[_bundleId].uri;
    }

    /// @dev Lets the calling contract create a bundle, by passing in a list of tokens and a unique id.
    function _createBundle(Token[] calldata _tokensToBind, uint256 _bundleId) internal {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        uint256 targetCount = _tokensToBind.length;

        require(targetCount > 0, "!Tokens");
        require(data.bundle[_bundleId].count == 0, "id exists");

        for (uint256 i = 0; i < targetCount; i += 1) {
            _checkTokenType(_tokensToBind[i]);
            data.bundle[_bundleId].tokens[i] = _tokensToBind[i];
        }

        data.bundle[_bundleId].count = targetCount;
    }

    /// @dev Lets the calling contract update a bundle, by passing in a list of tokens and a unique id.
    function _updateBundle(Token[] memory _tokensToBind, uint256 _bundleId) internal {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        require(_tokensToBind.length > 0, "!Tokens");

        uint256 currentCount = data.bundle[_bundleId].count;
        uint256 targetCount = _tokensToBind.length;
        uint256 check = currentCount > targetCount ? currentCount : targetCount;

        for (uint256 i = 0; i < check; i += 1) {
            if (i < targetCount) {
                _checkTokenType(_tokensToBind[i]);
                data.bundle[_bundleId].tokens[i] = _tokensToBind[i];
            } else if (i < currentCount) {
                delete data.bundle[_bundleId].tokens[i];
            }
        }

        data.bundle[_bundleId].count = targetCount;
    }

    /// @dev Lets the calling contract add a token to a bundle for a unique bundle id and index.
    function _addTokenInBundle(Token memory _tokenToBind, uint256 _bundleId) internal {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        _checkTokenType(_tokenToBind);
        uint256 id = data.bundle[_bundleId].count;

        data.bundle[_bundleId].tokens[id] = _tokenToBind;
        data.bundle[_bundleId].count += 1;
    }

    /// @dev Lets the calling contract update a token in a bundle for a unique bundle id and index.
    function _updateTokenInBundle(
        Token memory _tokenToBind,
        uint256 _bundleId,
        uint256 _index
    ) internal {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        require(_index < data.bundle[_bundleId].count, "index DNE");
        _checkTokenType(_tokenToBind);
        data.bundle[_bundleId].tokens[_index] = _tokenToBind;
    }

    /// @dev Checks if the type of asset-contract is same as the TokenType specified.
    function _checkTokenType(Token memory _token) internal view {
        if (_token.tokenType == TokenType.ERC721) {
            try IERC165(_token.assetContract).supportsInterface(0x80ac58cd) returns (bool supported721) {
                require(supported721, "!TokenType");
            } catch {
                revert("!TokenType");
            }
        } else if (_token.tokenType == TokenType.ERC1155) {
            try IERC165(_token.assetContract).supportsInterface(0xd9b67a26) returns (bool supported1155) {
                require(supported1155, "!TokenType");
            } catch {
                revert("!TokenType");
            }
        } else if (_token.tokenType == TokenType.ERC20) {
            if (_token.assetContract != CurrencyTransferLib.NATIVE_TOKEN) {
                // 0x36372b07
                try IERC165(_token.assetContract).supportsInterface(0x80ac58cd) returns (bool supported721) {
                    require(!supported721, "!TokenType");

                    try IERC165(_token.assetContract).supportsInterface(0xd9b67a26) returns (bool supported1155) {
                        require(!supported1155, "!TokenType");
                    } catch Error(string memory) {} catch {}
                } catch Error(string memory) {} catch {}
            }
        }
    }

    /// @dev Lets the calling contract set/update the uri of a particular bundle.
    function _setUriOfBundle(string memory _uri, uint256 _bundleId) internal {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        data.bundle[_bundleId].uri = _uri;
    }

    /// @dev Lets the calling contract delete a particular bundle.
    function _deleteBundle(uint256 _bundleId) internal {
        TokenBundleStorage.Data storage data = TokenBundleStorage.tokenBundleStorage();

        for (uint256 i = 0; i < data.bundle[_bundleId].count; i += 1) {
            delete data.bundle[_bundleId].tokens[i];
        }
        data.bundle[_bundleId].count = 0;
    }
}
