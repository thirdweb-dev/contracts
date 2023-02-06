// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { IDirectListings } from "../IMarketplace.sol";

library DirectListingsStorage {
    bytes32 public constant DIRECT_LISTINGS_STORAGE_POSITION = keccak256("direct.listings.storage");

    struct Data {
        uint256 totalListings;
        mapping(uint256 => IDirectListings.Listing) listings;
        mapping(uint256 => mapping(address => bool)) isBuyerApprovedForListing;
        mapping(uint256 => mapping(address => uint256)) currencyPriceForListing;
    }

    function directListingsStorage() internal pure returns (Data storage directListingsData) {
        bytes32 position = DIRECT_LISTINGS_STORAGE_POSITION;
        assembly {
            directListingsData.slot := position
        }
    }
}
