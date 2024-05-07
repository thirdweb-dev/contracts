// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import { IDirectListings } from "../IMarketplace.sol";

/**
 * @author  thirdweb.com
 */
library DirectListingsStorage {
    /// @custom:storage-location erc7201:direct.listings.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("direct.listings.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant DIRECT_LISTINGS_STORAGE_POSITION =
        0xa5370dfa5e46a36b8e1214352e211aa04006b977c8fd45a98e6b8c6e230ba000;

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
