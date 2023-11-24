// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces
import {RoyaltyPaymentsLogic} from "contracts/extension/plugin/RoyaltyPayments.sol";
import {MarketplaceV3, IPlatformFee} from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import {TWProxy} from "contracts/infra/TWProxy.sol";
import {ERC721Base} from "contracts/base/ERC721Base.sol";
import {MockRoyaltyEngineV1} from "../mocks/MockRoyaltyEngineV1.sol";

import {IDirectListings} from "contracts/prebuilts/marketplace/IMarketplace.sol";
import {MintraDirectListingsLogicStandalone} from
    "contracts/prebuilts/marketplace/direct-listings/MintraDirectListingsLogicStandalone.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

contract MintraDirectListingsLogicStandaloneTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;
    address public wizard;

    function setUp() public override {
        super.setUp();

        marketplaceDeployer = getActor(1);
        seller = getActor(2);
        buyer = getActor(3);
        wizard = getActor(4);

        // Deploy implementation.
        marketplace = address(
            new MintraDirectListingsLogicStandalone(
                address(weth), 
                address(erc20Aux), 
                address(platformFeeRecipient), 
                address(wizard)
            )
        );

        vm.prank(marketplaceDeployer);
        // marketplace = address(
        //     new TWProxy(
        //         impl,
        //         abi.encodeCall(
        //             MarketplaceV3.initialize,
        //             (marketplaceDeployer, "", new address[](0), marketplaceDeployer, 0)
        //         )
        //     )
        // );

        //vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function _setupERC721BalanceForSeller(address _seller, uint256 _numOfTokens) private {
        erc721.mint(_seller, _numOfTokens);
    }

    function test_state_initial() public {
        uint256 totalListings = MintraDirectListingsLogicStandalone(marketplace).totalListings();
        assertEq(totalListings, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_getValidListings_burnListedTokens() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);

        // Total listings incremented
        assertEq(MintraDirectListingsLogicStandalone(marketplace).totalListings(), 1);

        // burn listed token
        vm.prank(seller);
        erc721.burn(0);

        vm.warp(150);
        // Fetch listing and verify state.
        uint256 totalListings = MintraDirectListingsLogicStandalone(marketplace).totalListings();
        assertEq(MintraDirectListingsLogicStandalone(marketplace).getAllValidListings(0, totalListings - 1).length, 0);
    }

    function test_state_approvedCurrencies() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParams) = _setup_updateListing();
        address currencyToApprove = address(erc20); // same currency as main listing
        uint256 pricePerTokenForCurrency = 2 ether;

        // Seller approves currency for listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: approving listing currency with different price.");
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(
            listingId, currencyToApprove, pricePerTokenForCurrency
        );

        // change currency
        currencyToApprove = NATIVE_TOKEN;

        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(
            listingId, currencyToApprove, pricePerTokenForCurrency
        );

        assertEq(
            MintraDirectListingsLogicStandalone(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), true
        );
        assertEq(
            MintraDirectListingsLogicStandalone(marketplace).currencyPriceForListing(listingId, NATIVE_TOKEN),
            pricePerTokenForCurrency
        );

        // should revert when updating listing with an approved currency but different price
        listingParams.currency = NATIVE_TOKEN;
        vm.prank(seller);
        vm.expectRevert("Marketplace: price different from approved price");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParams);

        // change listingParams.pricePerToken to approved price
        listingParams.pricePerToken = pricePerTokenForCurrency;
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParams);
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

    function _setupListingForRoyaltyTests(address erc721TokenAddress) private returns (uint256 listingId) {
        // Sample listing parameters.
        address assetContract = erc721TokenAddress;
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 100 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = false;

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        IERC721(erc721TokenAddress).setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        listingId = MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function _buyFromListingForRoyaltyTests(uint256 listingId) private returns (uint256 totalPrice) {
        IDirectListings.Listing memory listing = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        totalPrice = pricePerToken * quantityToBuy;

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);
        uint256 bla = erc20.allowance(buyer, marketplace);

        console.log(totalPrice);
        console.log("bla1");
        console.log(bla);
        console.log(listing.currency);
        console.log(address(erc20));

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );
        console.log("done");
    }

    function test_noRoyaltyEngine_defaultERC2981Token() public {
        // create token with ERC2981
        address royaltyRecipient = address(0x12345);
        uint128 royaltyBps = 10;
        uint256 platformFeeBps = MintraDirectListingsLogicStandalone(marketplace).platformFeeBps();
        ERC721Base nft2981 = new ERC721Base(address(0x12345), "NFT 2981", "NFT2981", royaltyRecipient, royaltyBps);
        vm.prank(address(0x12345));
        nft2981.mintTo(seller, "");

        // 1. ========= Create listing =========

        uint256 listingId = _setupListingForRoyaltyTests(address(nft2981));
        console.log("here");
        // 2. ========= Buy from listing =========

        uint256 totalPrice = _buyFromListingForRoyaltyTests(listingId);
        console.log("here11");
        // 3. ======== Check balances after royalty payments ========

        {
            uint256 platforfee = (platformFeeBps * totalPrice) / 10_000;
            uint256 royaltyAmount = (royaltyBps * totalPrice) / 10_000;

            assertBalERC20Eq(address(erc20), platformFeeRecipient, platforfee);
            console.log("platforfee: %s", platforfee);

            // Royalty recipient receives correct amounts
            assertBalERC20Eq(address(erc20), royaltyRecipient, royaltyAmount);

            console.log("here2");
            // Seller gets total price minus royalty amount minus platform fee
            assertBalERC20Eq(address(erc20), seller, totalPrice - royaltyAmount - platforfee);
            console.log("here3");
        }
    }

    function test_revert_feesExceedTotalPrice() public {
        (MockRoyaltyEngineV1 royaltyEngine,,) = _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        // Set platform fee on marketplace
        address platformFeeRecipient = marketplaceDeployer;
        uint128 platformFeeBps = 10_000; // equal to max bps 10_000 or 100%
        vm.prank(marketplaceDeployer);
        IPlatformFee(marketplace).setPlatformFeeInfo(platformFeeRecipient, platformFeeBps);

        // 1. ========= Create listing =========

        _setupERC721BalanceForSeller(seller, 1);
        uint256 listingId = _setupListingForRoyaltyTests(address(erc721));

        // 2. ========= Buy from listing =========

        IDirectListings.Listing memory listing = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);

        vm.expectRevert("fees exceed the price");
        vm.prank(buyer);
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Create listing
    //////////////////////////////////////////////////////////////*/

    function test_state_createListing() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        uint256 listingId = MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);

        // Test consequent state of the contract.

        // Seller is still owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total listings incremented
        assertEq(MintraDirectListingsLogicStandalone(marketplace).totalListings(), 1);

        // Fetch listing and verify state.
        IDirectListings.Listing memory listing = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);

        assertEq(listing.listingId, listingId);
        assertEq(listing.listingCreator, seller);
        assertEq(listing.assetContract, assetContract);
        assertEq(listing.tokenId, tokenId);
        assertEq(listing.quantity, quantity);
        assertEq(listing.currency, currency);
        assertEq(listing.pricePerToken, pricePerToken);
        assertEq(listing.startTimestamp, startTimestamp);
        assertEq(listing.endTimestamp, endTimestamp);
        assertEq(listing.reserved, reserved);
        assertEq(uint256(listing.tokenType), uint256(IDirectListings.TokenType.ERC721));
    }

    function test_revert_createListing_notOwnerOfListedToken() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Don't mint to 'token to be listed' to the seller.
        address someWallet = getActor(1000);
        _setupERC721BalanceForSeller(someWallet, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), someWallet, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(someWallet);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_notApprovedMarketplaceToTransferToken() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Don't approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, false);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_listingZeroQuantity() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 0; // Listing ZERO quantity
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_listingInvalidQuantity() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 2; // Listing more than `1` quantity
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing invalid quantity.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_invalidStartTimestamp() public {
        uint256 blockTimestamp = 100 minutes;
        // Set block.timestamp
        vm.warp(blockTimestamp);

        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = uint128(blockTimestamp - 61 minutes); // start time is less than block timestamp.
        uint128 endTimestamp = uint128(startTimestamp + 1);
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid startTimestamp.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_invalidEndTimestamp() public {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = uint128(startTimestamp - 1); // End timestamp is less than start timestamp.
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_listingNonERC721OrERC1155Token() public {
        // Sample listing parameters.
        address assetContract = address(erc20);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        vm.expectRevert("Marketplace: listed token must be ERC1155 or ERC721.");
        MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    /*///////////////////////////////////////////////////////////////
                            Update listing
    //////////////////////////////////////////////////////////////*/

    function _setup_updateListing()
        private
        returns (uint256 listingId, IDirectListings.ListingParameters memory listingParams)
    {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(seller);
        listingId = MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_state_updateListing() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.pricePerToken = 2 ether;

        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);

        // Test consequent state of the contract.

        // Seller is still owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total listings not incremented on update.
        assertEq(MintraDirectListingsLogicStandalone(marketplace).totalListings(), 1);

        // Fetch listing and verify state.
        IDirectListings.Listing memory listing = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);

        assertEq(listing.listingId, listingId);
        assertEq(listing.listingCreator, seller);
        assertEq(listing.assetContract, listingParamsToUpdate.assetContract);
        assertEq(listing.tokenId, 0);
        assertEq(listing.quantity, listingParamsToUpdate.quantity);
        assertEq(listing.currency, listingParamsToUpdate.currency);
        assertEq(listing.pricePerToken, listingParamsToUpdate.pricePerToken);
        assertEq(listing.startTimestamp, listingParamsToUpdate.startTimestamp);
        assertEq(listing.endTimestamp, listingParamsToUpdate.endTimestamp);
        assertEq(listing.reserved, listingParamsToUpdate.reserved);
        assertEq(uint256(listing.tokenType), uint256(IDirectListings.TokenType.ERC721));
    }

    function test_revert_updateListing_notListingCreator() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        address notSeller = getActor(1000); // Someone other than the seller calls update.
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_notOwnerOfListedToken() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens but NOT to seller. A new tokenId will be listed.
        address notSeller = getActor(1000);
        _setupERC721BalanceForSeller(notSeller, 1);

        // Approve Marketplace to transfer token.
        vm.prank(notSeller);
        erc721.setApprovalForAll(marketplace, true);

        // Transfer away owned token.
        vm.prank(seller);
        erc721.transferFrom(seller, address(0x1234), 0);

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_notApprovedMarketplaceToTransferToken() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Don't approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, false);

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingZeroQuantity() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.quantity = 0; // Listing zero quantity

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingInvalidQuantity() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.quantity = 2; // Listing more than `1` of the ERC721 token

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing invalid quantity.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingNonERC721OrERC1155Token() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.assetContract = address(erc20); // Listing non ERC721 / ERC1155 token.

        // Grant ERC20 token asset role.
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc20));

        vm.prank(seller);
        vm.expectRevert("Marketplace: listed token must be ERC1155 or ERC721.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_invalidStartTimestamp() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        uint128 currentStartTimestamp = listingParamsToUpdate.startTimestamp;
        listingParamsToUpdate.startTimestamp = currentStartTimestamp - 1; // Retroactively decreasing startTimestamp.

        vm.warp(currentStartTimestamp + 50);
        vm.prank(seller);
        vm.expectRevert("Marketplace: listing already active.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_invalidEndTimestamp() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        uint128 currentStartTimestamp = listingParamsToUpdate.startTimestamp;
        listingParamsToUpdate.endTimestamp = currentStartTimestamp - 1; // End timestamp less than startTimestamp

        vm.prank(seller);
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    /*///////////////////////////////////////////////////////////////
                            Cancel listing
    //////////////////////////////////////////////////////////////*/

    function _setup_cancelListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId,) = _setup_updateListing();
        listing = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);
    }

    function test_state_cancelListing() public {
        (uint256 listingId, IDirectListings.Listing memory existingListingAtId) = _setup_cancelListing();

        // Verify existing listing at `listingId`
        assertEq(existingListingAtId.assetContract, address(erc721));

        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).cancelListing(listingId);

        // status should be `CANCELLED`
        IDirectListings.Listing memory cancelledListing =
            MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);
        assertTrue(cancelledListing.status == IDirectListings.Status.CANCELLED);
    }

    function test_revert_cancelListing_notListingCreator() public {
        (uint256 listingId, IDirectListings.Listing memory existingListingAtId) = _setup_cancelListing();

        // Verify existing listing at `listingId`
        assertEq(existingListingAtId.assetContract, address(erc721));

        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        MintraDirectListingsLogicStandalone(marketplace).cancelListing(listingId);
    }

    function test_revert_cancelListing_nonExistentListing() public {
        _setup_cancelListing();

        // Verify no listing exists at `nexListingId`
        uint256 nextListingId = MintraDirectListingsLogicStandalone(marketplace).totalListings();

        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid listing.");
        MintraDirectListingsLogicStandalone(marketplace).cancelListing(nextListingId);
    }

    /*///////////////////////////////////////////////////////////////
                        Approve buyer for listing
    //////////////////////////////////////////////////////////////*/

    function _setup_approveBuyerForListing() private returns (uint256 listingId) {
        (listingId,) = _setup_updateListing();
    }

    function test_state_approveBuyerForListing() public {
        uint256 listingId = _setup_approveBuyerForListing();
        bool toApprove = true;

        assertEq(MintraDirectListingsLogicStandalone(marketplace).getListing(listingId).reserved, true);

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, toApprove);

        assertEq(MintraDirectListingsLogicStandalone(marketplace).isBuyerApprovedForListing(listingId, buyer), true);
    }

    function test_revert_approveBuyerForListing_notListingCreator() public {
        uint256 listingId = _setup_approveBuyerForListing();
        bool toApprove = true;

        assertEq(MintraDirectListingsLogicStandalone(marketplace).getListing(listingId).reserved, true);

        // Someone other than the seller approves buyer for reserved listing.
        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, toApprove);
    }

    function test_revert_approveBuyerForListing_listingNotReserved() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();
        bool toApprove = true;

        assertEq(MintraDirectListingsLogicStandalone(marketplace).getListing(listingId).reserved, true);

        listingParamsToUpdate.reserved = false;

        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).updateListing(listingId, listingParamsToUpdate);

        assertEq(MintraDirectListingsLogicStandalone(marketplace).getListing(listingId).reserved, false);

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: listing not reserved.");
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, toApprove);
    }

    /*///////////////////////////////////////////////////////////////
                        Approve currency for listing
    //////////////////////////////////////////////////////////////*/

    function _setup_approveCurrencyForListing() private returns (uint256 listingId) {
        (listingId,) = _setup_updateListing();
    }

    function test_state_approveCurrencyForListing() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = NATIVE_TOKEN;
        uint256 pricePerTokenForCurrency = 2 ether;

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(
            listingId, currencyToApprove, pricePerTokenForCurrency
        );

        assertEq(
            MintraDirectListingsLogicStandalone(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), true
        );
        assertEq(
            MintraDirectListingsLogicStandalone(marketplace).currencyPriceForListing(listingId, NATIVE_TOKEN),
            pricePerTokenForCurrency
        );
    }

    function test_revert_approveCurrencyForListing_notListingCreator() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = NATIVE_TOKEN;
        uint256 pricePerTokenForCurrency = 2 ether;

        // Someone other than seller approves buyer for reserved listing.
        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(
            listingId, currencyToApprove, pricePerTokenForCurrency
        );
    }

    function test_revert_approveCurrencyForListing_reApprovingMainCurrency() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId).currency;
        uint256 pricePerTokenForCurrency = 2 ether;

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: approving listing currency with different price.");
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(
            listingId, currencyToApprove, pricePerTokenForCurrency
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Buy from listing
    //////////////////////////////////////////////////////////////*/

    function _setup_buyFromListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId,) = _setup_updateListing();
        listing = MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);
    }

    function test_state_buyFromListing() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);
        assertBalERC20Eq(address(erc20), buyer, totalPrice);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );

        // Verify that buyer is owner of listed tokens, post-sale.
        assertIsOwnerERC721(address(erc721), buyer, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Verify seller is paid total price.
        assertBalERC20Eq(address(erc20), buyer, 0);
        assertBalERC20Eq(address(erc20), seller, totalPrice);

        if (quantityToBuy == listing.quantity) {
            // Verify listing status is `COMPLETED` if listing tokens are all bought.
            IDirectListings.Listing memory completedListing =
                MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);
            assertTrue(completedListing.status == IDirectListings.Status.COMPLETED);
        }
    }

    function test_state_buyFromListing_nativeToken() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = NATIVE_TOKEN;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Approve NATIVE_TOKEN for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken);

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Deal requisite total price to buyer.
        vm.deal(buyer, totalPrice);
        uint256 buyerBalBefore = buyer.balance;
        uint256 sellerBalBefore = seller.balance;

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing{value: totalPrice}(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );

        // Verify that buyer is owner of listed tokens, post-sale.
        assertIsOwnerERC721(address(erc721), buyer, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Verify seller is paid total price.
        assertEq(buyer.balance, buyerBalBefore - totalPrice);
        assertEq(seller.balance, sellerBalBefore + totalPrice);

        if (quantityToBuy == listing.quantity) {
            // Verify listing status is `COMPLETED` if listing tokens are all bought.
            IDirectListings.Listing memory completedListing =
                MintraDirectListingsLogicStandalone(marketplace).getListing(listingId);
            assertTrue(completedListing.status == IDirectListings.Status.COMPLETED);
        }
    }

    function test_revert_buyFromListing_nativeToken_incorrectValueSent() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = NATIVE_TOKEN;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Approve NATIVE_TOKEN for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken);

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Deal requisite total price to buyer.
        vm.deal(buyer, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Marketplace: msg.value must exactly be the total price.");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing{value: totalPrice - 1}( // sending insufficient value
        listingId, buyFor, quantityToBuy, currency, totalPrice);
    }

    function test_revert_buyFromListing_unexpectedTotalPrice() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = NATIVE_TOKEN;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Approve NATIVE_TOKEN for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken);

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Deal requisite total price to buyer.
        vm.deal(buyer, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Unexpected total price");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing{value: totalPrice}(
            listingId,
            buyFor,
            quantityToBuy,
            currency,
            totalPrice + 1 // Pass unexpected total price
        );
    }

    function test_revert_buyFromListing_invalidCurrency() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);
        assertBalERC20Eq(address(erc20), buyer, totalPrice);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.

        assertEq(listing.currency, address(erc20));
        assertEq(
            MintraDirectListingsLogicStandalone(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN),
            false
        );

        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Paying in invalid currency.");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, NATIVE_TOKEN, totalPrice
        );
    }

    function test_revert_buyFromListing_buyerBalanceLessThanPrice() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice - 1); // Buyer balance less than total price
        assertBalERC20Eq(address(erc20), buyer, totalPrice - 1);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("!BAL20");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );
    }

    function test_revert_buyFromListing_notApprovedMarketplaceToTransferPrice() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);
        assertBalERC20Eq(address(erc20), buyer, totalPrice);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Don't approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.approve(marketplace, 0);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("!BAL20");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );
    }

    function test_revert_buyFromListing_buyingZeroQuantity() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = 0; // Buying zero quantity
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);
        assertBalERC20Eq(address(erc20), buyer, totalPrice);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Don't approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Buying invalid quantity");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );
    }

    function test_revert_buyFromListing_buyingMoreQuantityThanListed() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity + 1; // Buying more than listed.
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, tokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);
        assertBalERC20Eq(address(erc20), buyer, totalPrice);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Don't approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        // Buy tokens from listing.
        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Buying invalid quantity");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing(
            listingId, buyFor, quantityToBuy, currency, totalPrice
        );
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function _createListing(address _seller) private returns (uint256 listingId) {
        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        _setupERC721BalanceForSeller(_seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), _seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(_seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract, tokenId, quantity, currency, pricePerToken, startTimestamp, endTimestamp, reserved
        );

        vm.prank(_seller);
        listingId = MintraDirectListingsLogicStandalone(marketplace).createListing(listingParams);
    }

    function test_audit_native_tokens_locked() public {
        (uint256 listingId, IDirectListings.Listing memory existingListing) = _setup_buyFromListing();

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingListing.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingListing.assetContract, address(erc721));

        vm.warp(existingListing.startTimestamp);

        // No ether is locked in contract
        assertEq(marketplace.balance, 0);

        // buy from listing
        erc20.mint(buyer, 10 ether);
        vm.deal(buyer, 1 ether);

        vm.prank(seller);
        MintraDirectListingsLogicStandalone(marketplace).approveBuyerForListing(listingId, buyer, true);

        vm.startPrank(buyer);
        erc20.approve(marketplace, 10 ether);

        vm.expectRevert("Marketplace: invalid native tokens sent.");
        MintraDirectListingsLogicStandalone(marketplace).buyFromListing{value: 1 ether}(
            listingId, buyer, 1, address(erc20), 1 ether
        );
        vm.stopPrank();

        // 1 ether is temporary locked in contract
        assertEq(marketplace.balance, 0 ether);
    }
}
