// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library FeeType {
    uint256 internal constant PRIMARY_SALE = 0;
    uint256 internal constant ROYALTY = 1;
    uint256 internal constant MARKET_SALE = 2;
    uint256 internal constant SPLITS = 3;
}
