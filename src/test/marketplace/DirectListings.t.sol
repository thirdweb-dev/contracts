// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces
import { Map } from "contracts/marketplace/alt/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/alt/MarketplaceEntrypoint.sol";
import { DirectListings } from "contracts/marketplace/direct-listings/DirectListingsLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

import { IDirectListings } from "contracts/marketplace/IMarketplace.sol";

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

        // [6] Setup roles for seller and assets
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));

        vm.stopPrank();

        vm.label(address(entrypoint), "Entrypoint_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(directListings, "DirectListings_Extension");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function setupERC721BalanceForSeller(address _seller, uint256 _numOfTokens) private {
        erc721.mint(_seller, _numOfTokens);
    }

    function test_state_initial() public {
        uint256 totalListings = DirectListings(marketplace).totalListings();
        assertEq(totalListings, 0);
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        uint256 listingId = DirectListings(marketplace).createListing(listingParams);

        // Test consequent state of the contract.

        // Seller is still owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total listings incremented
        assertEq(DirectListings(marketplace).totalListings(), 1);

        // Fetch listing and verify state.
        IDirectListings.Listing memory listing = DirectListings(marketplace).getListing(listingId);

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
        setupERC721BalanceForSeller(someWallet, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), someWallet, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(someWallet);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        vm.expectRevert("!BALNFT");
        DirectListings(marketplace).createListing(listingParams);
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Don't approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, false);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        vm.expectRevert("!BALNFT");
        DirectListings(marketplace).createListing(listingParams);
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        vm.expectRevert("Listing zero quantity.");
        DirectListings(marketplace).createListing(listingParams);
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        vm.expectRevert("Listing invalid quantity.");
        DirectListings(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_invalidStartTimestamp() public {
        // Set block.timestamp
        vm.warp(100);

        // Sample listing parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = uint128(block.timestamp - 1); // start time is less than block timestamp.
        uint128 endTimestamp = uint128(startTimestamp + 1);
        bool reserved = true;

        // Mint the ERC721 tokens to seller. These tokens will be listed.
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        vm.expectRevert("invalid timestamps.");
        DirectListings(marketplace).createListing(listingParams);
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(seller);
        vm.expectRevert("invalid timestamps.");
        DirectListings(marketplace).createListing(listingParams);
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
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        // Grant ERC20 token asset role.
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc20));

        vm.prank(seller);
        vm.expectRevert("token must be ERC1155 or ERC721.");
        DirectListings(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_noListerRoleWhenRestrictionsActive() public {
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        // Revoke LISTER_ROLE from seller.
        vm.startPrank(marketplaceDeployer);
        assertEq(Permissions(marketplace).hasRole(keccak256("LISTER_ROLE"), address(0)), false);
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), seller);
        assertEq(Permissions(marketplace).hasRole(keccak256("LISTER_ROLE"), seller), false);

        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("!LISTER_ROLE");
        DirectListings(marketplace).createListing(listingParams);
    }

    function test_revert_createListing_noAssetRoleWhenRestrictionsActive() public {
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
        setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // List tokens.
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        // Revoke ASSET_ROLE from token to list.
        vm.startPrank(marketplaceDeployer);
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(0)), false);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(erc721));
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(erc721)), false);

        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("!ASSET_ROLE");
        DirectListings(marketplace).createListing(listingParams);
    }

    /*///////////////////////////////////////////////////////////////
                            Update listing
    //////////////////////////////////////////////////////////////*/

    function test_state_updateListing() public {}

    function test_revert_updateListing_notListingCreator() public {}

    function test_revert_updateListing_notOwnerOfListedToken() public {}

    function test_revert_updateListing_notApprovedMarketplaceToTransferToken() public {}

    function test_revert_updateListing_listingZeroQuantity() public {}

    function test_revert_updateListing_noAssetRoleWhenRestrictionsActive() public {}

    /*///////////////////////////////////////////////////////////////
                            Cancel listing
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelListing() public {}

    function test_revert_cancelListing_notListingCreator() public {}

    /*///////////////////////////////////////////////////////////////
                        Approve buyer for listing
    //////////////////////////////////////////////////////////////*/

    function test_state_approveBuyerForListing() public {}

    function test_revert_approveBuyerForListing_notListingCreator() public {}

    /*///////////////////////////////////////////////////////////////
                        Approve currency for listing
    //////////////////////////////////////////////////////////////*/

    function test_state_approveCurrencyForListing() public {}

    function test_revert_approveCurrencyForListing_notListingCreator() public {}

    /*///////////////////////////////////////////////////////////////
                        Buy from listing
    //////////////////////////////////////////////////////////////*/

    function test_state_buyFromListing() public {}

    function test_revert_buyFromListing_buyerBalanceLessThanPrice() public {}

    function test_revert_buyFromListing_notApprovedMarketplaceToTransferPrice() public {}

    function test_revert_buyFromListing_buyingZeroQuantity() public {}

    function test_revert_buyFromListing_buyingMoreQuantityThanListed() public {}

    function test_revert_buyFromListing_payingWithUnapprovedCurrency() public {}

    function test_revert_buyFromListing_payingIncorrectPrice() public {}

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function test_state_totalListings() public {}

    function test_state_getAllListings() public {}

    function test_state_getAllValidListings() public {}

    function test_state_getListing() public {}
}
