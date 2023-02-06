// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { IOffers } from "../IMarketplace.sol";

library OffersStorage {
    bytes32 public constant OFFERS_STORAGE_POSITION = keccak256("offers.storage");

    struct Data {
        uint256 totalOffers;
        mapping(uint256 => IOffers.Offer) offers;
    }

    function offersStorage() internal pure returns (Data storage offersData) {
        bytes32 position = OFFERS_STORAGE_POSITION;
        assembly {
            offersData.slot := position
        }
    }
}
