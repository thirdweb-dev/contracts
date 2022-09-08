// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC1155Wrapper {
    /**
     * @dev Burns and issues new tokens with same metadata.
     *
     */
    function exchange(uint256 tokenId, uint256 amount) external;
}
