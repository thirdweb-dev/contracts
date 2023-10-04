// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import { IEnglishAuctions } from "../IMarketplace.sol";

/**
 * @author  thirdweb.com
 */
library EnglishAuctionsStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant ENGLISH_AUCTIONS_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("english.auctions.storage")) - 1)) & ~bytes32(uint256(0xff));

    struct Data {
        uint256 totalAuctions;
        mapping(uint256 => IEnglishAuctions.Auction) auctions;
        mapping(uint256 => IEnglishAuctions.Bid) winningBid;
        mapping(uint256 => IEnglishAuctions.AuctionPayoutStatus) payoutStatus;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = ENGLISH_AUCTIONS_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
