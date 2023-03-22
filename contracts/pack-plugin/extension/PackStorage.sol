// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../interfaces/IPackVRFDirect.sol";

library PackStorage {
    bytes32 public constant PACK_STORAGE_POSITION = keccak256("pack.storage");

    struct Data {
        /// @dev The token Id of the next set of packs to be minted.
        uint256 nextTokenIdToMint;
        /// @dev Mapping from token ID => total circulating supply of token with that ID.
        mapping(uint256 => uint256) totalSupply;
        /// @dev Mapping from pack ID => The state of that set of packs.
        mapping(uint256 => IPackVRFDirect.PackInfo) packInfo;
    }

    function packStorage() internal pure returns (Data storage packData) {
        bytes32 position = PACK_STORAGE_POSITION;
        assembly {
            packData.slot := position
        }
    }
}
