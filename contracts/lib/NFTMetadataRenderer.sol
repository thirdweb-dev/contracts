// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* solhint-disable quotes */

/// @author thirdweb
/// credits: Zora

import "./Strings.sol";
import "../external-deps/openzeppelin/utils/Base64.sol";

/// NFT metadata library for rendering metadata associated with editions
library NFTMetadataRenderer {
    /**
     *  @notice Generate edition metadata from storage information as base64-json blob
     *  @dev Combines the media data and metadata
     * @param name Name of NFT in metadata
     * @param description Description of NFT in metadata
     * @param imageURI URI of image to render for edition
     * @param animationURI URI of animation to render for edition
     * @param tokenOfEdition Token ID for specific token
     */
    function createMetadataEdition(
        string memory name,
        string memory description,
        string memory imageURI,
        string memory animationURI,
        uint256 tokenOfEdition
    ) internal pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(imageURI, animationURI);
        bytes memory json = createMetadataJSON(name, description, _tokenMediaData, tokenOfEdition);
        return encodeMetadataJSON(json);
    }

    /**
     * @param name Name of NFT in metadata
     * @param description Description of NFT in metadata
     * @param mediaData Data for media to include in json object
     * @param tokenOfEdition Token ID for specific token
     */
    function createMetadataJSON(
        string memory name,
        string memory description,
        string memory mediaData,
        uint256 tokenOfEdition
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"name": "',
                name,
                " ",
                Strings.toString(tokenOfEdition),
                '", "',
                'description": "',
                description,
                '", "',
                mediaData,
                'properties": {"number": ',
                Strings.toString(tokenOfEdition),
                ', "name": "',
                name,
                '"}}'
            );
    }

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /// Generates edition metadata from storage information as base64-json blob
    /// Combines the media data and metadata
    /// @param imageUrl URL of image to render for edition
    /// @param animationUrl URL of animation to render for edition
    function tokenMediaData(string memory imageUrl, string memory animationUrl) internal pure returns (string memory) {
        bool hasImage = bytes(imageUrl).length > 0;
        bool hasAnimation = bytes(animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return string(abi.encodePacked('image": "', imageUrl, '", "animation_url": "', animationUrl, '", "'));
        }
        if (hasImage) {
            return string(abi.encodePacked('image": "', imageUrl, '", "'));
        }
        if (hasAnimation) {
            return string(abi.encodePacked('animation_url": "', animationUrl, '", "'));
        }

        return "";
    }
}
