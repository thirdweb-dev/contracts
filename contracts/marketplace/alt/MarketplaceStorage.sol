// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { IMarketplace } from "../../interfaces/marketplace/IMarketplace.sol";

library MarketplaceStorage {
    bytes32 public constant MARKETPLACE_STORAGE_POSITION = keccak256("marketplace.storage");

    // struct Data {
    //     ;
    // }

    // function marketplaceStorage() internal pure returns (Data storage marketplaceData) {
    //     bytes32 position = MARKETPLACE_STORAGE_POSITION;
    //     assembly {
    //         marketplaceData.slot := position
    //     }
    // }
}
