// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import { IOffers } from "../IMarketplace.sol";

/**
 * @author  thirdweb.com
 */
library OffersStorage {
    /// @custom:storage-location erc7201:offers.storage.storage
    bytes32 public constant OFFERS_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("offers.storage")) - 1));

    struct Data {
        uint256 totalOffers;
        mapping(uint256 => IOffers.Offer) offers;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = OFFERS_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
