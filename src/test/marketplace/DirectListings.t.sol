// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces
import { IDirectListings } from "contracts/marketplace/IMarketplace.sol";
import { Map } from "contracts/marketplace/alt/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/alt/MarketplaceEntrypoint.sol";
import { DirectListings } from "contracts/marketplace/direct-listings/DirectListingsLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

contract MarketplaceDirectListingsTest is BaseTest {
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

        // [2] Deploy `DirectListings`
        address directListings = address(new DirectListings(address(weth)));

        // [3] Index `DirectListings` functions in `Map`
        map.setExtension(DirectListings.totalListings.selector, directListings);
        map.setExtension(DirectListings.createListing.selector, directListings);
        map.setExtension(DirectListings.updateListing.selector, directListings);
        map.setExtension(DirectListings.cancelListing.selector, directListings);
        map.setExtension(DirectListings.approveBuyerForListing.selector, directListings);
        map.setExtension(DirectListings.approveCurrencyForListing.selector, directListings);
        map.setExtension(DirectListings.buyFromListing.selector, directListings);
        map.setExtension(DirectListings.getAllListings.selector, directListings);
        map.setExtension(DirectListings.getAllValidListings.selector, directListings);
        map.setExtension(DirectListings.getListing.selector, directListings);

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
        uint256 totalListings = DirectListings(marketplace).totalListings();
        assertEq(totalListings, 0);
    }
}
