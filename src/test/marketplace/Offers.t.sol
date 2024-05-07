// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces

import { PluginMap, IPluginMap } from "contracts/extension/plugin/PluginMap.sol";
import { RoyaltyPaymentsLogic } from "contracts/extension/plugin/RoyaltyPayments.sol";
import { MarketplaceV3, IPlatformFee } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { OffersLogic } from "contracts/prebuilts/marketplace/offers/OffersLogic.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { ERC721Base } from "contracts/base/ERC721Base.sol";
import { MockRoyaltyEngineV1 } from "../mocks/MockRoyaltyEngineV1.sol";

import { IOffers } from "contracts/prebuilts/marketplace/IMarketplace.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

contract MarketplaceOffersTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    function setUp() public override {
        super.setUp();

        marketplaceDeployer = getActor(1);
        seller = getActor(2);
        buyer = getActor(3);

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address impl = address(
            new MarketplaceV3(MarketplaceV3.MarketplaceConstructorParams(extensions, address(0), address(weth)))
        );

        vm.prank(marketplaceDeployer);
        marketplace = address(
            new TWProxy(
                impl,
                abi.encodeCall(
                    MarketplaceV3.initialize,
                    (marketplaceDeployer, "", new address[](0), marketplaceDeployer, 0)
                )
            )
        );

        // Setup roles for seller and assets
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(0));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));

        vm.stopPrank();

        vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `Offers`
        address offers = address(new OffersLogic());
        vm.label(offers, "Offers_Extension");

        // Extension: OffersLogic
        Extension memory extension_offers;
        extension_offers.metadata = ExtensionMetadata({
            name: "OffersLogic",
            metadataURI: "ipfs://Offers",
            implementation: offers
        });

        extension_offers.functions = new ExtensionFunction[](7);
        extension_offers.functions[0] = ExtensionFunction(OffersLogic.totalOffers.selector, "totalOffers()");
        extension_offers.functions[1] = ExtensionFunction(
            OffersLogic.makeOffer.selector,
            "makeOffer((address,uint256,uint256,address,uint256,uint256))"
        );
        extension_offers.functions[2] = ExtensionFunction(OffersLogic.cancelOffer.selector, "cancelOffer(uint256)");
        extension_offers.functions[3] = ExtensionFunction(OffersLogic.acceptOffer.selector, "acceptOffer(uint256)");
        extension_offers.functions[4] = ExtensionFunction(
            OffersLogic.getAllValidOffers.selector,
            "getAllValidOffers(uint256,uint256)"
        );
        extension_offers.functions[5] = ExtensionFunction(
            OffersLogic.getAllOffers.selector,
            "getAllOffers(uint256,uint256)"
        );
        extension_offers.functions[6] = ExtensionFunction(OffersLogic.getOffer.selector, "getOffer(uint256)");

        extensions[0] = extension_offers;
    }

    function test_state_initial() public {
        uint256 totalOffers = OffersLogic(marketplace).totalOffers();
        assertEq(totalOffers, 0);
    }

    /*///////////////////////////////////////////////////////////////
                Royalty Tests (incl Royalty Engine / Registry)
    //////////////////////////////////////////////////////////////*/

    function _setupRoyaltyEngine()
        private
        returns (
            MockRoyaltyEngineV1 royaltyEngine,
            address payable[] memory mockRecipients,
            uint256[] memory mockAmounts
        )
    {
        mockRecipients = new address payable[](2);
        mockAmounts = new uint256[](2);

        mockRecipients[0] = payable(address(0x12345));
        mockRecipients[1] = payable(address(0x56789));

        mockAmounts[0] = 10;
        mockAmounts[1] = 15;

        royaltyEngine = new MockRoyaltyEngineV1(mockRecipients, mockAmounts);
    }

    function _setupOfferForRoyaltyTests(address erc721TokenAddress) private returns (uint256 offerId) {
        // Sample offer parameters.
        address assetContract = erc721TokenAddress;
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
        offerId = OffersLogic(marketplace).makeOffer(offerParams);
    }

    function _acceptOfferForRoyaltyTests(uint256 offerId) private returns (uint256 totalPrice) {
        IOffers.Offer memory offer = OffersLogic(marketplace).getOffer(offerId);

        totalPrice = offer.totalPrice;

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        IERC721(offer.assetContract).setApprovalForAll(marketplace, true);

        // Accept offer
        vm.prank(seller);
        OffersLogic(marketplace).acceptOffer(offerId);
    }

    function test_royaltyEngine_tokenWithCustomRoyalties() public {
        (
            MockRoyaltyEngineV1 royaltyEngine,
            address payable[] memory customRoyaltyRecipients,
            uint256[] memory customRoyaltyAmounts
        ) = _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        // 1. ========= Make offer =========

        uint256 offerId = _setupOfferForRoyaltyTests(address(erc721));

        // 2. ========= Accept offer =========

        // Mint the ERC721 tokens to seller. These tokens will be sold.
        erc721.mint(seller, 1);
        uint256 totalPrice = _acceptOfferForRoyaltyTests(offerId);

        // 3. ======== Check balances after royalty payments ========

        {
            // Royalty recipients receive correct amounts
            assertBalERC20Eq(address(erc20), customRoyaltyRecipients[0], customRoyaltyAmounts[0]);
            assertBalERC20Eq(address(erc20), customRoyaltyRecipients[1], customRoyaltyAmounts[1]);

            // Seller gets total price minus royalty amounts
            assertBalERC20Eq(address(erc20), seller, totalPrice - customRoyaltyAmounts[0] - customRoyaltyAmounts[1]);
        }
    }

    function test_royaltyEngine_tokenWithERC2981() public {
        (MockRoyaltyEngineV1 royaltyEngine, , ) = _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        // create token with ERC2981
        address royaltyRecipient = address(0x12345);
        uint128 royaltyBps = 10;
        ERC721Base nft2981 = new ERC721Base(address(0x12345), "NFT 2981", "NFT2981", royaltyRecipient, royaltyBps);
        // Mint the ERC721 tokens to seller. These tokens will be sold.
        vm.prank(address(0x12345));
        nft2981.mintTo(seller, "");

        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(nft2981));

        // 1. ========= Make offer =========

        uint256 offerId = _setupOfferForRoyaltyTests(address(nft2981));

        // 2. ========= Accept offer =========

        uint256 totalPrice = _acceptOfferForRoyaltyTests(offerId);

        // 3. ======== Check balances after royalty payments ========

        {
            uint256 royaltyAmount = (royaltyBps * totalPrice) / 10_000;
            // Royalty recipient receives correct amounts
            assertBalERC20Eq(address(erc20), royaltyRecipient, royaltyAmount);

            // Seller gets total price minus royalty amount
            assertBalERC20Eq(address(erc20), seller, totalPrice - royaltyAmount);
        }
    }

    function test_noRoyaltyEngine_defaultERC2981Token() public {
        // create token with ERC2981
        address royaltyRecipient = address(0x12345);
        uint128 royaltyBps = 10;
        ERC721Base nft2981 = new ERC721Base(address(0x12345), "NFT 2981", "NFT2981", royaltyRecipient, royaltyBps);
        vm.prank(address(0x12345));
        nft2981.mintTo(seller, "");

        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(nft2981));

        // 1. ========= Make offer =========

        uint256 offerId = _setupOfferForRoyaltyTests(address(nft2981));

        // 2. ========= Accept offer =========

        uint256 totalPrice = _acceptOfferForRoyaltyTests(offerId);

        // 3. ======== Check balances after royalty payments ========

        {
            uint256 royaltyAmount = (royaltyBps * totalPrice) / 10_000;
            // Royalty recipient receives correct amounts
            assertBalERC20Eq(address(erc20), royaltyRecipient, royaltyAmount);

            // Seller gets total price minus royalty amount
            assertBalERC20Eq(address(erc20), seller, totalPrice - royaltyAmount);
        }
    }

    function test_royaltyEngine_correctlyDistributeAllFees() public {
        (
            MockRoyaltyEngineV1 royaltyEngine,
            address payable[] memory customRoyaltyRecipients,
            uint256[] memory customRoyaltyAmounts
        ) = _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        // Set platform fee on marketplace
        address platformFeeRecipient = marketplaceDeployer;
        uint128 platformFeeBps = 5;
        vm.prank(marketplaceDeployer);
        IPlatformFee(marketplace).setPlatformFeeInfo(platformFeeRecipient, platformFeeBps);

        // 1. ========= Make offer =========

        uint256 offerId = _setupOfferForRoyaltyTests(address(erc721));

        // 2. ========= Accept offer =========

        // Mint the ERC721 tokens to seller. These tokens will be sold.
        erc721.mint(seller, 1);
        uint256 totalPrice = _acceptOfferForRoyaltyTests(offerId);

        // 3. ======== Check balances after royalty payments ========

        {
            // Royalty recipients receive correct amounts
            assertBalERC20Eq(address(erc20), customRoyaltyRecipients[0], customRoyaltyAmounts[0]);
            assertBalERC20Eq(address(erc20), customRoyaltyRecipients[1], customRoyaltyAmounts[1]);

            // Platform fee recipient
            uint256 platformFeeAmount = (platformFeeBps * totalPrice) / 10_000;
            assertBalERC20Eq(address(erc20), platformFeeRecipient, platformFeeAmount);

            // Seller gets total price minus royalty amounts
            assertBalERC20Eq(
                address(erc20),
                seller,
                totalPrice - customRoyaltyAmounts[0] - customRoyaltyAmounts[1] - platformFeeAmount
            );
        }
    }

    function test_revert_feesExceedTotalPrice() public {
        (MockRoyaltyEngineV1 royaltyEngine, , ) = _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        // Set platform fee on marketplace
        address platformFeeRecipient = marketplaceDeployer;
        uint128 platformFeeBps = 10_000; // equal to max bps 10_000 or 100%
        vm.prank(marketplaceDeployer);
        IPlatformFee(marketplace).setPlatformFeeInfo(platformFeeRecipient, platformFeeBps);

        // 1. ========= Make offer =========

        uint256 offerId = _setupOfferForRoyaltyTests(address(erc721));

        // 2. ========= Accept offer =========

        // Mint the ERC721 tokens to seller. These tokens will be sold.
        erc721.mint(seller, 1);

        IOffers.Offer memory offer = OffersLogic(marketplace).getOffer(offerId);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        IERC721(offer.assetContract).setApprovalForAll(marketplace, true);

        // Accept offer
        vm.expectRevert("fees exceed the price");
        vm.prank(seller);
        OffersLogic(marketplace).acceptOffer(offerId);
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        // Test consequent state of the contract.

        // Total offers incremented
        assertEq(OffersLogic(marketplace).totalOffers(), 1);

        // Fetch listing and verify state.
        IOffers.Offer memory offer = OffersLogic(marketplace).getOffer(offerId);

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
        vm.expectRevert("Marketplace: insufficient currency balance.");
        OffersLogic(marketplace).makeOffer(offerParams);
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
        vm.expectRevert("Marketplace: insufficient currency balance.");
        OffersLogic(marketplace).makeOffer(offerParams);
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
        vm.expectRevert("Marketplace: wanted zero tokens.");
        OffersLogic(marketplace).makeOffer(offerParams);
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
        vm.expectRevert("Marketplace: wanted invalid quantity.");
        OffersLogic(marketplace).makeOffer(offerParams);
    }

    function test_revert_makeOffer_invalidExpirationTimestamp() public {
        uint256 blockTimestamp = 100 minutes;
        // Set block.timestamp
        vm.warp(blockTimestamp);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = blockTimestamp - 61 minutes;

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
        vm.expectRevert("Marketplace: invalid expiration timestamp.");
        OffersLogic(marketplace).makeOffer(offerParams);
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
        vm.expectRevert("Marketplace: token must be ERC1155 or ERC721.");
        OffersLogic(marketplace).makeOffer(offerParams);
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
        OffersLogic(marketplace).makeOffer(offerParams);
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        IOffers.Offer memory offer = OffersLogic(marketplace).getOffer(offerId);

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
        OffersLogic(marketplace).cancelOffer(offerId);

        // Total offers count shouldn't change
        assertEq(OffersLogic(marketplace).totalOffers(), 1);

        // status should be `CANCELLED`
        IOffers.Offer memory cancelledOffer = OffersLogic(marketplace).getOffer(offerId);
        assertTrue(cancelledOffer.status == IOffers.Status.CANCELLED);
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        vm.prank(address(0x345));
        vm.expectRevert("!Offeror");
        OffersLogic(marketplace).cancelOffer(offerId);
    }

    /*///////////////////////////////////////////////////////////////
                            Accept Offer
    //////////////////////////////////////////////////////////////*/

    function test_state_acceptOffer() public {
        // set owner of NFT
        erc721.mint(seller, 1);

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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        // accept offer
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        OffersLogic(marketplace).acceptOffer(offerId);
        vm.stopPrank();

        // Total offers count shouldn't change
        assertEq(OffersLogic(marketplace).totalOffers(), 1);

        // status should be `COMPLETED`
        IOffers.Offer memory completedOffer = OffersLogic(marketplace).getOffer(offerId);
        assertTrue(completedOffer.status == IOffers.Status.COMPLETED);

        // check states after accepting offer
        assertEq(erc721.ownerOf(tokenId), buyer);
        assertEq(erc20.balanceOf(seller), totalPrice);
        assertEq(erc20.balanceOf(buyer), 0);
    }

    function test_revert_acceptOffer_notOwnedRequiredTokens() public {
        // set owner of NFT to address other than seller
        erc721.mint(address(0x345), 1);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens. (but not owned)
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        // accept offer
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        OffersLogic(marketplace).acceptOffer(offerId);
        vm.stopPrank();
    }

    function test_revert_acceptOffer_notApprovedMarketplaceToTransferOfferedTokens() public {
        // set owner of NFT
        erc721.mint(seller, 1);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens. (but not owned)
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        // accept offer, without approving NFT to marketplace
        vm.startPrank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        OffersLogic(marketplace).acceptOffer(offerId);
        vm.stopPrank();
    }

    function test_revert_acceptOffer_offerorBalanceLessThanPrice() public {
        // set owner of NFT
        erc721.mint(seller, 1);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens. (but not owned)
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        // reduce erc20 balance of buyer
        vm.prank(buyer);
        erc20.burn(totalPrice);

        // accept offer
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        vm.expectRevert("Marketplace: insufficient currency balance.");
        OffersLogic(marketplace).acceptOffer(offerId);
        vm.stopPrank();
    }

    function test_revert_acceptOffer_notApprovedMarketplaceToTransferPrice() public {
        // set owner of NFT
        erc721.mint(seller, 1);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        // mint total-price to buyer
        erc20.mint(buyer, totalPrice);

        // Approve Marketplace to transfer currency tokens. (but not owned)
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
        uint256 offerId = OffersLogic(marketplace).makeOffer(offerParams);

        // remove erc20 approval
        vm.prank(buyer);
        erc20.approve(marketplace, 0);

        // accept offer
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        vm.expectRevert("Marketplace: insufficient currency balance.");
        OffersLogic(marketplace).acceptOffer(offerId);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function test_state_getAllOffers() public {
        uint256[] memory offerIds = new uint256[](5);
        uint256[] memory tokenIds = new uint256[](5);

        // mint total-price to buyer
        erc20.mint(buyer, 1000 ether);

        // Approve Marketplace to transfer currency tokens. (but not owned)
        vm.prank(buyer);
        erc20.approve(marketplace, 1000 ether);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 totalPrice = 1 ether;
        uint256 expirationTimestamp = 200;

        IOffers.OfferParams memory offerParams;

        for (uint256 i = 0; i < 5; i += 1) {
            tokenIds[i] = i;

            // make offer
            offerParams = IOffers.OfferParams(
                assetContract,
                tokenIds[i],
                quantity,
                currency,
                totalPrice,
                expirationTimestamp
            );

            vm.prank(buyer);
            offerIds[i] = OffersLogic(marketplace).makeOffer(offerParams);
        }

        IOffers.Offer[] memory allOffers = OffersLogic(marketplace).getAllOffers(0, 4);
        assertEq(allOffers.length, 5);

        for (uint256 i = 0; i < 5; i += 1) {
            assertEq(allOffers[i].offerId, offerIds[i]);
            assertEq(allOffers[i].offeror, buyer);
            assertEq(allOffers[i].assetContract, assetContract);
            assertEq(allOffers[i].tokenId, tokenIds[i]);
            assertEq(allOffers[i].quantity, quantity);
            assertEq(allOffers[i].currency, currency);
            assertEq(allOffers[i].totalPrice, totalPrice);
            assertEq(allOffers[i].expirationTimestamp, expirationTimestamp);
            assertEq(uint256(allOffers[i].tokenType), uint256(IOffers.TokenType.ERC721));
        }
    }

    function test_state_getAllValidOffers() public {
        uint256[] memory offerIds = new uint256[](5);
        uint256[] memory tokenIds = new uint256[](5);

        // mint total-price to buyer
        erc20.mint(buyer, 5 ether);

        // Approve Marketplace to transfer currency tokens. (but not owned)
        vm.prank(buyer);
        erc20.approve(marketplace, 5 ether);

        // Sample offer parameters.
        address assetContract = address(erc721);
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 expirationTimestamp = 200;

        IOffers.OfferParams memory offerParams;

        for (uint256 i = 0; i < 5; i += 1) {
            tokenIds[i] = i;

            // make offer, with total-price as i
            offerParams = IOffers.OfferParams(
                assetContract,
                tokenIds[i],
                quantity,
                currency,
                (i + 1) * 1 ether,
                expirationTimestamp
            );

            vm.prank(buyer);
            offerIds[i] = OffersLogic(marketplace).makeOffer(offerParams);
        }

        vm.prank(buyer);
        erc20.burn(2 ether); // reduce balance to make some offers invalid

        IOffers.Offer[] memory allOffers = OffersLogic(marketplace).getAllValidOffers(0, 4);
        assertEq(allOffers.length, 3);

        for (uint256 i = 0; i < 3; i += 1) {
            assertEq(allOffers[i].offerId, offerIds[i]);
            assertEq(allOffers[i].offeror, buyer);
            assertEq(allOffers[i].assetContract, assetContract);
            assertEq(allOffers[i].tokenId, tokenIds[i]);
            assertEq(allOffers[i].quantity, quantity);
            assertEq(allOffers[i].currency, currency);
            assertEq(allOffers[i].totalPrice, (i + 1) * 1 ether);
            assertEq(allOffers[i].expirationTimestamp, expirationTimestamp);
            assertEq(uint256(allOffers[i].tokenType), uint256(IOffers.TokenType.ERC721));
        }

        // create an offer, and check the offers returned post its expiry
        offerParams = IOffers.OfferParams(assetContract, 5, quantity, currency, 10, 10);

        vm.prank(buyer);
        OffersLogic(marketplace).makeOffer(offerParams);

        vm.warp(10);
        allOffers = OffersLogic(marketplace).getAllValidOffers(0, 5);
        assertEq(allOffers.length, 3);
    }
}
