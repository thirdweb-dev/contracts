// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { IDutchAuctions } from "../IMarketplace.sol";

library DutchAuctionsStorage {
    bytes32 public constant DUTCH_AUCTIONS_STORAGE_POSITION = keccak256("dutch.auctions.storage");

    struct Data {
        uint256 totalAuctions;
        mapping(uint256 => IDutchAuctions.Auction) auctions;
        mapping(uint256 => IDutchAuctions.AuctionPayoutStatus) payoutStatus;
    }

    function dutchAuctionsStorage() internal pure returns (Data storage dutchAuctionsData) {
        bytes32 position = DUTCH_AUCTIONS_STORAGE_POSITION;
        assembly {
            dutchAuctionsData.slot := position
        }
    }
}
