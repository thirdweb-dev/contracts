// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IBurnableERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}
