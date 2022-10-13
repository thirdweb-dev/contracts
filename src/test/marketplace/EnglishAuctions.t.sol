// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces
import { Map } from "contracts/marketplace/alt/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/alt/MarketplaceEntrypoint.sol";
import { EnglishAuctions } from "contracts/marketplace/english-auctions/EnglishAuctionsLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

contract MarketplaceEnglishAuctionsTest is BaseTest {
    // Target contract
    address public marketplace;

    // Participants
    address public adminDeployer;
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    function setUp() public override {
        super.setUp();

        adminDeployer = getActor(0);
        marketplaceDeployer = getActor(1);
        seller = getActor(2);
        buyer = getActor(3);

        setupMarketplace(adminDeployer, marketplaceDeployer);
    }

    function setupMarketplace(address _adminDeployer, address _marketplaceDeployer) private {
        vm.startPrank(_adminDeployer);

        // [1] Deploy `Map`.
        Map map = new Map();

        // [2] Deploy `EnglishAuctions`
        address englishAuctions = address(new EnglishAuctions(address(weth)));

        // [3] Index `EnglishAuctions` functions in `Map`
        map.setExtension(EnglishAuctions.createAuction.selector, englishAuctions);
        map.setExtension(EnglishAuctions.cancelAuction.selector, englishAuctions);
        map.setExtension(EnglishAuctions.collectAuctionPayout.selector, englishAuctions);
        map.setExtension(EnglishAuctions.collectAuctionTokens.selector, englishAuctions);
        map.setExtension(EnglishAuctions.bidInAuction.selector, englishAuctions);
        map.setExtension(EnglishAuctions.isNewWinningBid.selector, englishAuctions);
        map.setExtension(EnglishAuctions.getAuction.selector, englishAuctions);
        map.setExtension(EnglishAuctions.getAllAuctions.selector, englishAuctions);
        map.setExtension(EnglishAuctions.getWinningBid.selector, englishAuctions);
        map.setExtension(EnglishAuctions.isAuctionExpired.selector, englishAuctions);
        map.setExtension(EnglishAuctions.totalAuctions.selector, englishAuctions);

        // [4] Deploy `MarketplaceEntrypoint`

        MarketplaceEntrypoint entrypoint = new MarketplaceEntrypoint(address(map));

        vm.stopPrank();

        // [5] Deploy proxy pointing to `MarkeptlaceEntrypoint`
        vm.prank(_marketplaceDeployer);
        marketplace = address(
            new TWProxy(
                address(entrypoint),
                abi.encodeCall(
                    MarketplaceEntrypoint.initialize,
                    (_marketplaceDeployer, "", new address[](0), _marketplaceDeployer, 0)
                )
            )
        );
    }

    function test_state_initial() public {
        uint256 totoalAuctions = EnglishAuctions(marketplace).totalAuctions();
        assertEq(totoalAuctions, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Create Auction
    //////////////////////////////////////////////////////////////*/

    function test_state_createAuction() public {}

    function test_revert_createAuction_notOwnerOfAuctionedToken() public {}

    function test_revert_createAuction_notApprovedMarketplaceToTransferToken() public {}

    function test_revert_createAuction_auctioningZeroQuantity() public {}

    function test_revert_createAuction_noBidOrTimeBuffer() public {}

    function test_revert_createAuction_noListerRoleWhenRestrictionsActive() public {}

    function test_revert_createAuction_noAssetRoleWhenRestrictionsActive() public {}

    /*///////////////////////////////////////////////////////////////
                            Cancel Auction
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelAuction() public {}

    function test_revert_cancelAuction_bidsAlreadyMade() public {}

    /*///////////////////////////////////////////////////////////////
                        Collect Auction Payout
    //////////////////////////////////////////////////////////////*/

    function test_state_collectAuctionPayout() public {}

    function test_revert_collectAuctionPayout_auctionNotExpired() public {}

    function test_revert_collectAuctionPayout_noBidsInAuction() public {}

    /*///////////////////////////////////////////////////////////////
                        Collect Auction Tokens
    //////////////////////////////////////////////////////////////*/

    function test_state_collectAuctionTokes() public {}

    function test_revert_collectAuctionTokens_auctionNotExpired() public {}

    /*///////////////////////////////////////////////////////////////
                            Bid In Auction
    //////////////////////////////////////////////////////////////*/

    function test_state_bidInAuction() public {}

    function test_revert_bidInAuction_auctionExpired() public {}

    function test_revert_bidInAuction_notOwnerOfBidTokens() public {}

    function test_revert_bidInAuction_notApprovedMarketplaceToTransferToken() public {}

    function test_revert_bidInAuction_notNewWinningBid() public {}

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function test_state_isNewWinningBid() public {}

    function test_revert_isNewWinningBid() public {}

    function test_state_getAuction() public {}

    function test_state_getAllAuctions() public {}

    function test_state_getWinningBid() public {}

    function test_revert_getWinningBid() public {}

    function test_state_isAuctionExpired() public {}

    function test_revert_isAuctionExpired() public {}
}
