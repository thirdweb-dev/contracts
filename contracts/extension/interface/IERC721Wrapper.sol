// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC721Wrapper {
    /**
     * @dev Burns and issues new token with same metadata.
     *
     */
    function exchange(uint256 tokenId) external;
}
