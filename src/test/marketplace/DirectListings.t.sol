// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces
import { Map } from "contracts/marketplace/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/entrypoint/MarketplaceEntrypoint.sol";
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
        map.setExtension(DirectListings.isBuyerApprovedForListing.selector, directListings);
        map.setExtension(DirectListings.isCurrencyApprovedForListing.selector, directListings);
        map.setExtension(DirectListings.currencyPriceForListing.selector, directListings);
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

    function _setupERC721BalanceForSeller(address _seller, uint256 _numOfTokens) private {
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
        _setupERC721BalanceForSeller(seller, 1);

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
        vm.expectRevert("Marketplace: not owner or approved tokens.");
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
        _setupERC721BalanceForSeller(seller, 1);

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
        vm.expectRevert("Marketplace: not owner or approved tokens.");
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
        _setupERC721BalanceForSeller(seller, 1);

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
        vm.expectRevert("Marketplace: listing zero quantity.");
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
        _setupERC721BalanceForSeller(seller, 1);

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
        vm.expectRevert("Marketplace: listing invalid quantity.");
        DirectListings(marketplace).createListing(listingParams);
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
        vm.expectRevert("Marketplace: invalid timestamps.");
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
        _setupERC721BalanceForSeller(seller, 1);

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
        vm.expectRevert("Marketplace: invalid timestamps.");
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
        vm.expectRevert("Marketplace: listed token must be ERC1155 or ERC721.");
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
        _setupERC721BalanceForSeller(seller, 1);

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
        _setupERC721BalanceForSeller(seller, 1);

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
        listingId = DirectListings(marketplace).createListing(listingParams);
    }

    function test_state_updateListing() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.tokenId = 1; // New tokenId `1` to be listed instead of `0`

        vm.prank(seller);
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);

        // Test consequent state of the contract.

        // Seller is still owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total listings not incremented on update.
        assertEq(DirectListings(marketplace).totalListings(), 1);

        // Fetch listing and verify state.
        IDirectListings.Listing memory listing = DirectListings(marketplace).getListing(listingId);

        assertEq(listing.listingId, listingId);
        assertEq(listing.listingCreator, seller);
        assertEq(listing.assetContract, listingParamsToUpdate.assetContract);
        assertEq(listing.tokenId, 1);
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

        listingParamsToUpdate.tokenId = 1; // New tokenId `1` to be listed instead of `0`

        address notSeller = getActor(1000); // Someone other than the seller calls update.
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_notOwnerOfListedToken() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens but NOT to seller. A new tokenId will be listed.
        address notSeller = getActor(1000);
        _setupERC721BalanceForSeller(notSeller, 1);

        // Approve Marketplace to transfer token.
        vm.prank(notSeller);
        erc721.setApprovalForAll(marketplace, true);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.tokenId = 1; // New tokenId `1` to be listed instead of `0`

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
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

        listingParamsToUpdate.tokenId = 1; // New tokenId `1` to be listed instead of `0`

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingZeroQuantity() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.tokenId = 1; // New tokenId `1` to be listed instead of `0`
        listingParamsToUpdate.quantity = 0; // Listing zero quantity

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingInvalidQuantity() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.tokenId = 1; // New tokenId `1` to be listed instead of `0`
        listingParamsToUpdate.quantity = 2; // Listing more than `1` of the ERC721 token

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing invalid quantity.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
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
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
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

        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid timestamps.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
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
        vm.expectRevert("Marketplace: invalid timestamps.");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_noAssetRoleWhenRestrictionsActive() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Revoke ASSET_ROLE from token to list.
        vm.startPrank(marketplaceDeployer);
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(0)), false);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(erc721));
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(erc721)), false);

        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("!ASSET_ROLE");
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    /*///////////////////////////////////////////////////////////////
                            Cancel listing
    //////////////////////////////////////////////////////////////*/

    function _setup_cancelListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId, ) = _setup_updateListing();
        listing = DirectListings(marketplace).getListing(listingId);
    }

    function test_state_cancelListing() public {
        (uint256 listingId, IDirectListings.Listing memory existingListingAtId) = _setup_cancelListing();

        // Verify existing listing at `listingId`
        assertEq(existingListingAtId.assetContract, address(erc721));

        vm.prank(seller);
        DirectListings(marketplace).cancelListing(listingId);

        // Verify listing at `listingId` doesn't exist
        vm.expectRevert("Marketplace: listing does not exist.");
        DirectListings(marketplace).getListing(listingId);
    }

    function test_revert_cancelListing_notListingCreator() public {
        (uint256 listingId, IDirectListings.Listing memory existingListingAtId) = _setup_cancelListing();

        // Verify existing listing at `listingId`
        assertEq(existingListingAtId.assetContract, address(erc721));

        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListings(marketplace).cancelListing(listingId);
    }

    function test_revert_cancelListing_nonExistentListing() public {
        _setup_cancelListing();

        // Verify no listing exists at `nexListingId`
        uint256 nextListingId = DirectListings(marketplace).totalListings();

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing does not exist.");
        DirectListings(marketplace).cancelListing(nextListingId);
    }

    /*///////////////////////////////////////////////////////////////
                        Approve buyer for listing
    //////////////////////////////////////////////////////////////*/

    function _setup_approveBuyerForListing() private returns (uint256 listingId) {
        (listingId, ) = _setup_updateListing();
    }

    function test_state_approveBuyerForListing() public {
        uint256 listingId = _setup_approveBuyerForListing();
        bool toApprove = true;

        assertEq(DirectListings(marketplace).getListing(listingId).reserved, true);

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, toApprove);

        assertEq(DirectListings(marketplace).isBuyerApprovedForListing(listingId, buyer), true);
    }

    function test_revert_approveBuyerForListing_notListingCreator() public {
        uint256 listingId = _setup_approveBuyerForListing();
        bool toApprove = true;

        assertEq(DirectListings(marketplace).getListing(listingId).reserved, true);

        // Someone other than the seller approves buyer for reserved listing.
        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, toApprove);
    }

    function test_revert_approveBuyerForListing_listingNotReserved() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();
        bool toApprove = true;

        assertEq(DirectListings(marketplace).getListing(listingId).reserved, true);

        listingParamsToUpdate.reserved = false;

        vm.prank(seller);
        DirectListings(marketplace).updateListing(listingId, listingParamsToUpdate);

        assertEq(DirectListings(marketplace).getListing(listingId).reserved, false);

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: listing not reserved.");
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, toApprove);
    }

    /*///////////////////////////////////////////////////////////////
                        Approve currency for listing
    //////////////////////////////////////////////////////////////*/

    function _setup_approveCurrencyForListing() private returns (uint256 listingId) {
        (listingId, ) = _setup_updateListing();
    }

    function test_state_approveCurrencyForListing() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = NATIVE_TOKEN;
        uint256 pricePerTokenForCurrency = 2 ether;
        bool toApprove = true;

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        DirectListings(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency,
            toApprove
        );

        assertEq(DirectListings(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), true);
        assertEq(
            DirectListings(marketplace).currencyPriceForListing(listingId, NATIVE_TOKEN),
            pricePerTokenForCurrency
        );
    }

    function test_revert_approveCurrencyForListing_notListingCreator() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = NATIVE_TOKEN;
        uint256 pricePerTokenForCurrency = 2 ether;
        bool toApprove = true;

        // Someone other than seller approves buyer for reserved listing.
        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListings(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency,
            toApprove
        );
    }

    function test_revert_approveCurrencyForListing_reApprovingMainCurrency() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = DirectListings(marketplace).getListing(listingId).currency;
        uint256 pricePerTokenForCurrency = 2 ether;
        bool toApprove = true;

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: Re-approving main listing currency.");
        DirectListings(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency,
            toApprove
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Buy from listing
    //////////////////////////////////////////////////////////////*/

    function _setup_buyFromListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId, ) = _setup_updateListing();
        listing = DirectListings(marketplace).getListing(listingId);
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
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);

        // Verify that buyer is owner of listed tokens, post-sale.
        assertIsOwnerERC721(address(erc721), buyer, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Verify seller is paid total price.
        assertBalERC20Eq(address(erc20), buyer, 0);
        assertBalERC20Eq(address(erc20), seller, totalPrice);

        if (quantityToBuy == listing.quantity) {
            // Verify listing data is deleted if listing tokens are all bought.
            vm.expectRevert("Marketplace: listing does not exist.");
            DirectListings(marketplace).getListing(listingId);
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
        DirectListings(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken, true);

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing{ value: totalPrice }(
            listingId,
            buyFor,
            quantityToBuy,
            currency,
            totalPrice
        );

        // Verify that buyer is owner of listed tokens, post-sale.
        assertIsOwnerERC721(address(erc721), buyer, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Verify seller is paid total price.
        assertEq(buyer.balance, buyerBalBefore - totalPrice);
        assertEq(seller.balance, sellerBalBefore + totalPrice);

        if (quantityToBuy == listing.quantity) {
            // Verify listing data is deleted if listing tokens are all bought.
            vm.expectRevert("Marketplace: listing does not exist.");
            DirectListings(marketplace).getListing(listingId);
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
        DirectListings(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken, true);

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing{ value: totalPrice - 1 }( // sending insufficient value
            listingId,
            buyFor,
            quantityToBuy,
            currency,
            totalPrice
        );
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
        DirectListings(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken, true);

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing{ value: totalPrice }(
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
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        assertEq(DirectListings(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), false);

        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Paying in invalid currency.");
        DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, NATIVE_TOKEN, totalPrice);
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
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
            assetContract,
            tokenId,
            quantity,
            currency,
            pricePerToken,
            startTimestamp,
            endTimestamp,
            reserved
        );

        vm.prank(_seller);
        listingId = DirectListings(marketplace).createListing(listingParams);
    }
}

contract IssueC2_MarketplaceDirectListingsTest is BaseTest {
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
        map.setExtension(DirectListings.isBuyerApprovedForListing.selector, directListings);
        map.setExtension(DirectListings.isCurrencyApprovedForListing.selector, directListings);
        map.setExtension(DirectListings.currencyPriceForListing.selector, directListings);
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

    function _setupERC721BalanceForSeller(address _seller, uint256 _numOfTokens) private {
        erc721.mint(_seller, _numOfTokens);
    }

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
        listingId = DirectListings(marketplace).createListing(listingParams);
    }

    function _setup_buyFromListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId, ) = _setup_updateListing();
        listing = DirectListings(marketplace).getListing(listingId);
    }

    function test_state_buyFromListing_after_update() public {
        (uint256 listingId, IDirectListings.Listing memory listing) = _setup_buyFromListing();

        address buyFor = buyer;
        uint256 quantityToBuy = listing.quantity;
        address currency = listing.currency;
        uint256 pricePerToken = listing.pricePerToken;
        uint256 totalPrice = pricePerToken * quantityToBuy;

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListings(marketplace).approveBuyerForListing(listingId, buyer, true);

        // Verify that seller is owner of listed tokens, pre-sale.
        // This token (Id = 0) was created in the above _setup_buyFromListing
        uint256[] memory expectedTokenIds = new uint256[](1);
        expectedTokenIds[0] = 0;
        assertIsOwnerERC721(address(erc721), seller, expectedTokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, expectedTokenIds);

        // Mint a new token. This is token we will "swap out" via updateListing
        // It should be tokenId of 1
        _setupERC721BalanceForSeller(seller, 1);

        // Verify that seller is owner of new token, pre-sale.
        uint256[] memory swappedTokenIds = new uint256[](1);
        swappedTokenIds[0] = 1;
        assertIsOwnerERC721(address(erc721), seller, swappedTokenIds);
        assertIsNotOwnerERC721(address(erc721), buyer, swappedTokenIds);

        // Mint requisite total price to buyer.
        erc20.mint(buyer, totalPrice);
        assertBalERC20Eq(address(erc20), buyer, totalPrice);
        assertBalERC20Eq(address(erc20), seller, 0);

        // Approve marketplace to transfer currency
        vm.prank(buyer);
        erc20.increaseAllowance(marketplace, totalPrice);

        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Create ListingParameters with new tokenId (1) and update
        IDirectListings.ListingParameters memory listingParams = IDirectListings.ListingParameters(
            address(erc721),
            1,
            1,
            address(erc20),
            1 ether,
            100,
            200,
            true
        );
        vm.prank(seller);
        vm.expectRevert("Marketplace: cannot update what token is listed.");
        DirectListings(marketplace).updateListing(listingId, listingParams);

        // Buy listing
        // vm.warp(listing.startTimestamp);
        // vm.prank(buyer);
        // DirectListings(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);

        // // Buyer is owner of the swapped out token (tokenId = 1) and not the expected (tokenId = 0)
        // assertIsOwnerERC721(address(erc721), buyer, swappedTokenIds);
        // assertIsNotOwnerERC721(address(erc721), buyer, expectedTokenIds);

        // // Verify seller is paid total price.
        // assertBalERC20Eq(address(erc20), buyer, 0);
        // assertBalERC20Eq(address(erc20), seller, totalPrice);
    }
}
