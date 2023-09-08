// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import { IDirectListings } from "../IMarketplace.sol";

/**
 * @author  thirdweb.com
 */
library DirectListingsStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant DIRECT_LISTINGS_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("direct.listings.storage")) - 1));

    struct Data {
        uint256 totalListings;
        mapping(uint256 => IDirectListings.Listing) listings;
        mapping(uint256 => mapping(address => bool)) isBuyerApprovedForListing;
        mapping(uint256 => mapping(address => uint256)) currencyPriceForListing;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = DIRECT_LISTINGS_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
