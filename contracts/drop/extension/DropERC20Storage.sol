// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library DropERC20Storage {
    bytes32 public constant DROP_ERC20_STORAGE_POSITION = keccak256("drop.erc20.storage");

    struct Data {
        /// @dev Global max total supply of tokens.
        uint256 maxTotalSupply;
    }

    function dropERC20Storage() internal pure returns (Data storage dropERC20Data) {
        bytes32 position = DROP_ERC20_STORAGE_POSITION;
        assembly {
            dropERC20Data.slot := position
        }
    }
}
