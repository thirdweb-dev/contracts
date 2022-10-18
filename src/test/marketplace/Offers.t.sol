// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces

import { Map } from "contracts/marketplace/alt/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/alt/MarketplaceEntrypoint.sol";
import { Offers } from "contracts/marketplace/offers/OffersLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

import { IOffers } from "contracts/marketplace/IMarketplace.sol";

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

        // [6] Setup roles for seller and assets
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));

        vm.stopPrank();

        vm.label(address(entrypoint), "Entrypoint_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(offers, "Offers_Extension");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function test_state_initial() public {
        uint256 totalOffers = Offers(marketplace).totalOffers();
        assertEq(totalOffers, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Make Offer
    //////////////////////////////////////////////////////////////*/

    function test_state_makeOffer() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        uint256 offerId = Offers(marketplace).makeOffer(offerParams);

        // Test consequent state of the contract.

        // Total offers incremented
        assertEq(Offers(marketplace).totalOffers(), 1);

        // Fetch listing and verify state.
        IOffers.Offer memory offer = Offers(marketplace).getOffer(offerId);

        assertEq(offer.offerId, offerId);
        assertEq(offer.offeror, buyer);
        assertEq(offer.assetContract, assetContract);
        assertEq(offer.tokenId, tokenId);
        assertEq(offer.quantity, quantity);
        assertEq(offer.currency, currency);
        assertEq(offer.totalPrice, totalPrice);
        assertEq(offer.expirationTimestamp, expirationTimestamp);
        assertEq(uint256(offer.tokenType), uint256(IOffers.TokenType.ERC721));
    }

    function test_revert_makeOffer_notOwnerOfOfferedTokens() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // Approve Marketplace to transfer currency tokens. (without owning)
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        vm.expectRevert("!BAL20");
        Offers(marketplace).makeOffer(offerParams);
    }

    function test_revert_makeOffer_notApprovedMarketplaceToTransferTokens() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer, but not approved to marketplace
        erc20.mint(buyer, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        vm.expectRevert("!BAL20");
        Offers(marketplace).makeOffer(offerParams);
    }

    function test_revert_makeOffer_wantedZeroTokens() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 0;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        vm.expectRevert("zero quantity.");
        Offers(marketplace).makeOffer(offerParams);
    }

    function test_revert_makeOffer_invalidQuantity() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 2; // Asking for more than `1` quantity of erc721 tokenId
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        vm.expectRevert("invalid quantity.");
        Offers(marketplace).makeOffer(offerParams);
    }

    function test_revert_makeOffer_invalidExpirationTimestamp() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = block.timestamp;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        vm.expectRevert("invalid expiration.");
        Offers(marketplace).makeOffer(offerParams);
    }

    function test_revert_makeOffer_invalidAssetContract() public {
        // Sample offer parameters.
        address assetContract = address(erc20);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = block.timestamp;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        // Grant ERC20 token asset role.
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc20));

        vm.prank(buyer);
        vm.expectRevert("token must be ERC1155 or ERC721.");
        Offers(marketplace).makeOffer(offerParams);
    }

    function test_revert_createListing_noAssetRoleWhenRestrictionsActive() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = block.timestamp;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        // Revoke ASSET_ROLE from token to list.
        vm.startPrank(marketplaceDeployer);
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(0)), false);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(erc721));
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(erc721)), false);

        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert("!ASSET_ROLE");
        Offers(marketplace).makeOffer(offerParams);
    }

    /*///////////////////////////////////////////////////////////////
                            Cancel Offer
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelOffer() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        uint256 offerId = Offers(marketplace).makeOffer(offerParams);

        IOffers.Offer memory offer = Offers(marketplace).getOffer(offerId);

        assertEq(offer.offerId, offerId);
        assertEq(offer.offeror, buyer);
        assertEq(offer.assetContract, assetContract);
        assertEq(offer.tokenId, tokenId);
        assertEq(offer.quantity, quantity);
        assertEq(offer.currency, currency);
        assertEq(offer.totalPrice, totalPrice);
        assertEq(offer.expirationTimestamp, expirationTimestamp);
        assertEq(uint256(offer.tokenType), uint256(IOffers.TokenType.ERC721));

        vm.prank(buyer);
        Offers(marketplace).cancelOffer(offerId);

        // Total offers count shouldn't change
        assertEq(Offers(marketplace).totalOffers(), 1);

        bytes memory err = "DNE";
        vm.expectRevert(err);
        offer = Offers(marketplace).getOffer(offerId);
    }

    function test_revert_cancelOffer_callerNotOfferor() public {
        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens.
        vm.prank(buyer);
        erc20.approve(marketplace, totalPrice);

        // Make offer.
        IOffers.OfferParams memory offerParams = IOffers.OfferParams(
            assetContract,
            tokenId,
            quantity,
            currency,
            totalPrice,
            expirationTimestamp
        );

        vm.prank(buyer);
        uint256 offerId = Offers(marketplace).makeOffer(offerParams);

        vm.prank(address(0x345));
        vm.expectRevert("!Offeror");
        Offers(marketplace).cancelOffer(offerId);
    }

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
