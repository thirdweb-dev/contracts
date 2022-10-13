// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces

import { Map } from "contracts/marketplace/alt/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/alt/MarketplaceEntrypoint.sol";
import { Offers } from "contracts/marketplace/offers/OffersLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

contract MarketplaceOffersTest is BaseTest {
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

        // [2] Deploy `Offers`
        address offers = address(new Offers());

        // [3] Index `Offers` functions in `Map`
        map.setExtension(Offers.totalOffers.selector, offers);
        map.setExtension(Offers.makeOffer.selector, offers);
        map.setExtension(Offers.cancelOffer.selector, offers);
        map.setExtension(Offers.acceptOffer.selector, offers);
        map.setExtension(Offers.getAllValidOffers.selector, offers);
        map.setExtension(Offers.getAllOffers.selector, offers);
        map.setExtension(Offers.getOffer.selector, offers);

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
        uint256 totalOffers = Offers(marketplace).totalOffers();
        assertEq(totalOffers, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Make Offer
    //////////////////////////////////////////////////////////////*/

    function test_state_makeOffer() public {}

    function test_revert_makeOffer_notOwnerOfOfferedTokens() public {}

    function test_revert_makeOffer_notApprovedMarketplaceToTransferTokens() public {}

    function test_revert_makeOffer_wantedZeroTokens() public {}

    /*///////////////////////////////////////////////////////////////
                            Cancel Offer
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelOffer() public {}

    function test_revert_cancelOffer_callerNotOfferor() public {}

    /*///////////////////////////////////////////////////////////////
                            Accept Offer
    //////////////////////////////////////////////////////////////*/

    function test_state_acceptOffer() public {}

    function test_revert_acceptOffer_notOwnedOfferedTokens() public {}

    function test_revert_acceptOffer_notApprovedMarketplaceToTransferOfferedTokens() public {}

    function test_revert_acceptOffer_offerorBalanceLessThanPrice() public {}

    function test_revert_acceptOffer_notApprovedMarketplaceToTransferPrice() public {}

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function test_state_getOffer() public {}

    function test_state_getAllOffers() public {}

    function test_state_getAllValidOffers() public {}
}
