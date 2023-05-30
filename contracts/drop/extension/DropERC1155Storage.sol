// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library DropERC1155Storage {
    bytes32 public constant DROP_ERC1155_STORAGE_POSITION = keccak256("drop.erc1155.storage");

    struct Data {
        // Token name
        string name;
        // Token symbol
        string symbol;
        /// @dev Mapping from token ID => total circulating supply of tokens with that ID.
        mapping(uint256 => uint256) totalSupply;
        /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
        mapping(uint256 => uint256) maxTotalSupply;
        /// @dev Mapping from token ID => the address of the recipient of primary sales.
        mapping(uint256 => address) saleRecipient;
    }

    function dropERC1155Storage() internal pure returns (Data storage dropERC1155Data) {
        bytes32 position = DROP_ERC1155_STORAGE_POSITION;
        assembly {
            dropERC1155Data.slot := position
        }
    }
}
