// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library DropERC721Storage {
    bytes32 public constant DROP_ERC721_STORAGE_POSITION = keccak256("drop.erc721.storage");

    struct Data {
        /// @dev Global max total supply of NFTs.
        uint256 maxTotalSupply;
    }

    function dropERC721Storage() internal pure returns (Data storage dropERC721Data) {
        bytes32 position = DROP_ERC721_STORAGE_POSITION;
        assembly {
            dropERC721Data.slot := position
        }
    }
}
