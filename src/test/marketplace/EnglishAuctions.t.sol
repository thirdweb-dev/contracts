// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../utils/BaseTest.sol";

// Test contracts and interfaces
import { Map } from "contracts/marketplace/alt/Map.sol";
import { MarketplaceEntrypoint } from "contracts/marketplace/alt/MarketplaceEntrypoint.sol";
import { EnglishAuctions } from "contracts/marketplace/english-auctions/EnglishAuctionsLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

import { IEnglishAuctions } from "contracts/marketplace/IMarketplace.sol";

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

        // [6] Setup roles for seller and assets
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));

        vm.stopPrank();

        vm.label(address(entrypoint), "Entrypoint_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(englishAuctions, "EnglishAuctions_Extension");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function _setupERC721BalanceForSeller(address _seller, uint256 _numOfTokens) private {
        erc721.mint(_seller, _numOfTokens);
    }

    function test_state_initial() public {
        uint256 totoalAuctions = EnglishAuctions(marketplace).totalAuctions();
        assertEq(totoalAuctions, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Create Auction
    //////////////////////////////////////////////////////////////*/

    function test_state_createAuction() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        uint256 auctionId = EnglishAuctions(marketplace).createAuction(auctionParams);

        // Test consequent state of the contract.

        // Marketplace is owner of token.
        assertIsOwnerERC721(address(erc721), marketplace, tokenIds);

        // Total listings incremented
        assertEq(EnglishAuctions(marketplace).totalAuctions(), 1);

        // Fetch listing and verify state.
        IEnglishAuctions.Auction memory auction = EnglishAuctions(marketplace).getAuction(auctionId);

        assertEq(auction.auctionId, auctionId);
        assertEq(auction.auctionCreator, seller);
        assertEq(auction.assetContract, assetContract);
        assertEq(auction.tokenId, tokenId);
        assertEq(auction.quantity, quantity);
        assertEq(auction.currency, currency);
        assertEq(auction.minimumBidAmount, minimumBidAmount);
        assertEq(auction.buyoutBidAmount, buyoutBidAmount);
        assertEq(auction.timeBufferInSeconds, timeBufferInSeconds);
        assertEq(auction.bidBufferBps, bidBufferBps);
        assertEq(auction.startTimestamp, startTimestamp);
        assertEq(auction.endTimestamp, endTimestamp);
        assertEq(uint256(auction.tokenType), uint256(IEnglishAuctions.TokenType.ERC721));
    }

    function test_revert_createAuction_notOwnerOfAuctionedToken() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Don't mint to 'token to be auctioned' to the seller.
        address someWallet = getActor(1000);
        _setupERC721BalanceForSeller(someWallet, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), someWallet, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(someWallet);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("!BALNFT");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_notApprovedMarketplaceToTransferToken() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Don't approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, false);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("!BALNFT");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_auctioningZeroQuantity() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 0;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("zero quantity.");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_invalidQuantity() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 2; // Listing more than `1` quantity
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("invalid quantity.");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_noBidOrTimeBuffer() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 0;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("zero time-buffer.");
        EnglishAuctions(marketplace).createAuction(auctionParams);

        timeBufferInSeconds = 10 seconds;
        bidBufferBps = 0;

        auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("zero bid-buffer.");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_invalidBidAmounts() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 10 ether; // set minimumBidAmount greater than buyoutBidAmount
        uint256 buyoutBidAmount = 1 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("RESERVE");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_invalidStartTimestamp() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = uint64(block.timestamp - 1); // start time is less than block timestamp.
        uint64 endTimestamp = startTimestamp + 1;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("invalid timestamps.");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_invalidEndTimestamp() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = startTimestamp - 1;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        vm.expectRevert("invalid timestamps.");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_invalidAssetContract() public {
        // Sample auction parameters.
        address assetContract = address(erc20);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = startTimestamp - 1;

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        // Grant ERC20 token asset role.
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc20));

        vm.prank(seller);
        vm.expectRevert("token must be ERC1155 or ERC721.");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_noListerRoleWhenRestrictionsActive() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        // Revoke LISTER_ROLE from seller.
        vm.startPrank(marketplaceDeployer);
        assertEq(Permissions(marketplace).hasRole(keccak256("LISTER_ROLE"), address(0)), false);
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), seller);
        assertEq(Permissions(marketplace).hasRole(keccak256("LISTER_ROLE"), seller), false);

        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("!LISTER_ROLE");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_revert_createAuction_noAssetRoleWhenRestrictionsActive() public {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        // Revoke ASSET_ROLE from token to list.
        vm.startPrank(marketplaceDeployer);
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(0)), false);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(erc721));
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(erc721)), false);

        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("!ASSET_ROLE");
        EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    /*///////////////////////////////////////////////////////////////
                            Cancel Auction
    //////////////////////////////////////////////////////////////*/

    function _setup_newAuction() private returns (uint256 auctionId) {
        // Sample auction parameters.
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 10 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100;
        uint64 endTimestamp = 200;

        // Mint the ERC721 tokens to seller. These tokens will be auctioned.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Approve Marketplace to transfer token.
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        // Auction tokens.
        IEnglishAuctions.AuctionParameters memory auctionParams = IEnglishAuctions.AuctionParameters(
            assetContract,
            tokenId,
            quantity,
            currency,
            minimumBidAmount,
            buyoutBidAmount,
            timeBufferInSeconds,
            bidBufferBps,
            startTimestamp,
            endTimestamp
        );

        vm.prank(seller);
        auctionId = EnglishAuctions(marketplace).createAuction(auctionParams);
    }

    function test_state_cancelAuction() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.prank(seller);
        EnglishAuctions(marketplace).cancelAuction(auctionId);

        // Test consequent states.

        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total auction count should include deleted auctions too
        assertEq(EnglishAuctions(marketplace).totalAuctions(), 1);

        // Revert when fetching deleted auction.
        bytes memory err = "DNE";
        vm.expectRevert(err);
        EnglishAuctions(marketplace).getAuction(auctionId);
    }

    function test_revert_cancelAuction_bidsAlreadyMade() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place bid
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("bids already made");
        EnglishAuctions(marketplace).cancelAuction(auctionId);
    }

    /*///////////////////////////////////////////////////////////////
                            Bid In Auction
    //////////////////////////////////////////////////////////////*/

    function test_state_bidInAuction_firstBid() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place bid
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();

        (address bidder, address currency, uint256 bidAmount) = EnglishAuctions(marketplace).getWinningBid(auctionId);

        // Test consequent states.
        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), marketplace, tokenIds);
        assertEq(erc20.balanceOf(marketplace), 1 ether);
        assertEq(erc20.balanceOf(buyer), 0);
        assertEq(buyer, bidder);
        assertEq(currency, address(erc20));
        assertEq(bidAmount, 1 ether);
    }

    function test_state_bidInAuction_secondBid() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place first bid
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();

        (address bidder, address currency, uint256 bidAmount) = EnglishAuctions(marketplace).getWinningBid(auctionId);

        // Test consequent states.
        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), marketplace, tokenIds);
        assertEq(erc20.balanceOf(marketplace), 1 ether);
        assertEq(erc20.balanceOf(buyer), 0);
        assertEq(buyer, bidder);
        assertEq(currency, address(erc20));
        assertEq(bidAmount, 1 ether);

        // place second winning bid
        erc20.mint(address(0x345), 2 ether);
        vm.startPrank(address(0x345));
        erc20.approve(marketplace, 2 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 2 ether);
        vm.stopPrank();

        (bidder, currency, bidAmount) = EnglishAuctions(marketplace).getWinningBid(auctionId);

        // Test consequent states.
        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), marketplace, tokenIds);
        assertEq(erc20.balanceOf(marketplace), 2 ether);
        assertEq(erc20.balanceOf(buyer), 1 ether);
        assertEq(erc20.balanceOf(address(0x345)), 0);
        assertEq(address(0x345), bidder);
        assertEq(currency, address(erc20));
        assertEq(bidAmount, 2 ether);
    }

    function test_state_bidInAuction_buyoutBid() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place first bid
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();

        (address bidder, address currency, uint256 bidAmount) = EnglishAuctions(marketplace).getWinningBid(auctionId);

        // Test consequent states.
        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), marketplace, tokenIds);
        assertEq(erc20.balanceOf(marketplace), 1 ether);
        assertEq(erc20.balanceOf(buyer), 0);
        assertEq(buyer, bidder);
        assertEq(currency, address(erc20));
        assertEq(bidAmount, 1 ether);

        // place buyout bid
        erc20.mint(address(0x345), 10 ether);
        vm.startPrank(address(0x345));
        erc20.approve(marketplace, 10 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 10 ether);
        vm.stopPrank();

        (bidder, currency, bidAmount) = EnglishAuctions(marketplace).getWinningBid(auctionId);

        // Test consequent states.
        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), address(0x345), tokenIds);
        assertEq(erc20.balanceOf(marketplace), 10 ether);
        assertEq(erc20.balanceOf(buyer), 1 ether);
        assertEq(erc20.balanceOf(address(0x345)), 0);
        assertEq(address(0x345), bidder);
        assertEq(currency, address(erc20));
        assertEq(bidAmount, 10 ether);
    }

    function test_revert_bidInAuction_inactiveAuction() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        // place bid before start-time
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        vm.expectRevert("inactive auction.");
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();

        // place bid after end-time
        vm.warp(existingAuction.endTimestamp);

        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        vm.expectRevert("inactive auction.");
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();
    }

    function test_revert_bidInAuction_notOwnerOfBidTokens() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place bid
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();
    }

    function test_revert_bidInAuction_notApprovedMarketplaceToTransferToken() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place bid
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        vm.expectRevert("ERC20: insufficient allowance");
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();
    }

    function test_revert_bidInAuction_notNewWinningBid_firstBid() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place first bid less than minimum bid amount
        erc20.mint(buyer, 0.5 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 0.5 ether);
        vm.expectRevert("not winning bid.");
        EnglishAuctions(marketplace).bidInAuction(auctionId, 0.5 ether);
        vm.stopPrank();
    }

    function test_revert_bidInAuction_notNewWinningBid_secondBid() public {
        uint256 auctionId = _setup_newAuction();
        IEnglishAuctions.Auction memory existingAuction = EnglishAuctions(marketplace).getAuction(auctionId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = existingAuction.tokenId;

        // Verify existing auction at `auctionId`
        assertEq(existingAuction.assetContract, address(erc721));

        vm.warp(existingAuction.startTimestamp);

        // place first bid
        erc20.mint(buyer, 1 ether);
        vm.startPrank(buyer);
        erc20.approve(marketplace, 1 ether);
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();

        (address bidder, address currency, uint256 bidAmount) = EnglishAuctions(marketplace).getWinningBid(auctionId);

        // Test consequent states.
        // Seller is owner of token.
        assertIsOwnerERC721(address(erc721), marketplace, tokenIds);
        assertEq(erc20.balanceOf(marketplace), 1 ether);
        assertEq(erc20.balanceOf(buyer), 0);
        assertEq(buyer, bidder);
        assertEq(currency, address(erc20));
        assertEq(bidAmount, 1 ether);

        // place second bid less-than/equal-to previous winning bid
        erc20.mint(address(0x345), 1 ether);
        vm.startPrank(address(0x345));
        erc20.approve(marketplace, 1 ether);
        vm.expectRevert("not winning bid.");
        EnglishAuctions(marketplace).bidInAuction(auctionId, 1 ether);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Collect Auction Payout
    //////////////////////////////////////////////////////////////*/

    function test_state_collectAuctionPayout() public {}

    function test_revert_collectAuctionPayout_auctionNotExpired() public {}

    function test_revert_collectAuctionPayout_noBidsInAuction() public {}

    /*///////////////////////////////////////////////////////////////
                        Collect Auction Tokens
    //////////////////////////////////////////////////////////////*/

    function test_state_collectAuctionTokens() public {}

    function test_revert_collectAuctionTokens_auctionNotExpired() public {}

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
