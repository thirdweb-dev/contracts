// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import "../../../utils/BaseTest.sol";

// Test contracts and interfaces
import { RoyaltyPaymentsLogic } from "contracts/extension/plugin/RoyaltyPayments.sol";
import { MarketplaceV3, IPlatformFee } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { EnglishAuctionsLogic } from "contracts/prebuilts/marketplace/english-auctions/EnglishAuctionsLogic.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { ERC721Base } from "contracts/base/ERC721Base.sol";

import { IEnglishAuctions } from "contracts/prebuilts/marketplace/IMarketplace.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

contract InvalidToken {
    function supportsInterface(bytes4) public pure returns (bool) {
        return false;
    }
}

contract CreateAuctionTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    // Auction parameters
    IEnglishAuctions.AuctionParameters internal auctionParams;

    // Events
    /// @dev Emitted when a new auction is created.
    event NewAuction(
        address indexed auctionCreator,
        uint256 indexed auctionId,
        address indexed assetContract,
        IEnglishAuctions.Auction auction
    );

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
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), address(0));

        vm.stopPrank();

        vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");

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

        // Auction tokens.
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

        // Mint NFT to seller.
        erc721.mint(seller, 1); // to, amount
        erc1155.mint(seller, 0, 100); // to, id, amount
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `EnglishAuctions`
        address englishAuctions = address(new EnglishAuctionsLogic(address(weth)));
        vm.label(englishAuctions, "EnglishAuctions_Extension");

        // Extension: EnglishAuctionsLogic
        Extension memory extension_englishAuctions;
        extension_englishAuctions.metadata = ExtensionMetadata({
            name: "EnglishAuctionsLogic",
            metadataURI: "ipfs://EnglishAuctions",
            implementation: englishAuctions
        });

        extension_englishAuctions.functions = new ExtensionFunction[](12);
        extension_englishAuctions.functions[0] = ExtensionFunction(
            EnglishAuctionsLogic.totalAuctions.selector,
            "totalAuctions()"
        );
        extension_englishAuctions.functions[1] = ExtensionFunction(
            EnglishAuctionsLogic.createAuction.selector,
            "createAuction((address,uint256,uint256,address,uint256,uint256,uint64,uint64,uint64,uint64))"
        );
        extension_englishAuctions.functions[2] = ExtensionFunction(
            EnglishAuctionsLogic.cancelAuction.selector,
            "cancelAuction(uint256)"
        );
        extension_englishAuctions.functions[3] = ExtensionFunction(
            EnglishAuctionsLogic.collectAuctionPayout.selector,
            "collectAuctionPayout(uint256)"
        );
        extension_englishAuctions.functions[4] = ExtensionFunction(
            EnglishAuctionsLogic.collectAuctionTokens.selector,
            "collectAuctionTokens(uint256)"
        );
        extension_englishAuctions.functions[5] = ExtensionFunction(
            EnglishAuctionsLogic.bidInAuction.selector,
            "bidInAuction(uint256,uint256)"
        );
        extension_englishAuctions.functions[6] = ExtensionFunction(
            EnglishAuctionsLogic.isNewWinningBid.selector,
            "isNewWinningBid(uint256,uint256)"
        );
        extension_englishAuctions.functions[7] = ExtensionFunction(
            EnglishAuctionsLogic.getAuction.selector,
            "getAuction(uint256)"
        );
        extension_englishAuctions.functions[8] = ExtensionFunction(
            EnglishAuctionsLogic.getAllAuctions.selector,
            "getAllAuctions(uint256,uint256)"
        );
        extension_englishAuctions.functions[9] = ExtensionFunction(
            EnglishAuctionsLogic.getAllValidAuctions.selector,
            "getAllValidAuctions(uint256,uint256)"
        );
        extension_englishAuctions.functions[10] = ExtensionFunction(
            EnglishAuctionsLogic.getWinningBid.selector,
            "getWinningBid(uint256)"
        );
        extension_englishAuctions.functions[11] = ExtensionFunction(
            EnglishAuctionsLogic.isAuctionExpired.selector,
            "isAuctionExpired(uint256)"
        );

        extensions[0] = extension_englishAuctions;
    }

    function test_createAuction_whenCallerDoesntHaveListerRole() public {
        assertEq(Permissions(marketplace).hasRole(keccak256("LISTER_ROLE"), seller), false);

        vm.prank(seller);
        vm.expectRevert("!LISTER_ROLE");
        EnglishAuctionsLogic(marketplace).createAuction(auctionParams);
    }

    modifier whenCallerHasListerRole() {
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        _;
    }

    function test_createAuction_whenAssetDoesnHaveAssetRole() public whenCallerHasListerRole {
        assertEq(Permissions(marketplace).hasRole(keccak256("ASSET_ROLE"), address(erc721)), false);

        vm.prank(seller);
        vm.expectRevert("!ASSET_ROLE");
        EnglishAuctionsLogic(marketplace).createAuction(auctionParams);
    }

    modifier whenAssetHasAssetRole() {
        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        _;
    }

    function test_createAuction_whenTokenIsInvalid() public whenCallerHasListerRole whenAssetHasAssetRole {
        address newToken = address(new InvalidToken());

        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), newToken);

        auctionParams.assetContract = newToken;

        vm.prank(seller);
        vm.expectRevert("Marketplace: auctioned token must be ERC1155 or ERC721.");
        EnglishAuctionsLogic(marketplace).createAuction(auctionParams);
    }

    modifier whenTokenIsValid() {
        _;
    }

    function test_createAuction_whenAuctionParamsAreInvalid()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenTokenIsValid
    {
        // This is one way for params to be invalid. `_validateNewAuction` has its own tests.
        auctionParams.quantity = 0;

        vm.prank(seller);
        vm.expectRevert("Marketplace: auctioning zero quantity.");
        EnglishAuctionsLogic(marketplace).createAuction(auctionParams);
    }

    modifier whenAuctionParamsAreValid() {
        _;
    }

    function test_createAuction_whenAuctionParamsAreValid()
        public
        whenCallerHasListerRole
        whenAssetHasAssetRole
        whenTokenIsValid
        whenAuctionParamsAreValid
    {
        uint256 expectedAuctionId = 0;

        assertEq(EnglishAuctionsLogic(marketplace).totalAuctions(), 0);
        assertEq(erc721.ownerOf(0), seller);
        assertEq(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).assetContract, address(0));

        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        IEnglishAuctions.Auction memory dummyAuction;

        vm.prank(seller);
        vm.expectEmit(true, true, true, false);
        emit NewAuction(seller, expectedAuctionId, auctionParams.assetContract, dummyAuction);
        EnglishAuctionsLogic(marketplace).createAuction(auctionParams);

        assertEq(EnglishAuctionsLogic(marketplace).totalAuctions(), 1);
        assertEq(erc721.ownerOf(0), marketplace);
        assertEq(EnglishAuctionsLogic(marketplace).getAllAuctions(0, 0).length, 1);

        assertEq(EnglishAuctionsLogic(marketplace).getAllValidAuctions(0, 0).length, 0);
        vm.warp(auctionParams.startTimestamp);
        assertEq(EnglishAuctionsLogic(marketplace).getAllValidAuctions(0, 0).length, 1);

        assertEq(EnglishAuctionsLogic(marketplace).getAllAuctions(0, 0).length, 1);
        assertEq(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).auctionId, expectedAuctionId);
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).assetContract,
            auctionParams.assetContract
        );
        assertEq(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).tokenId, auctionParams.tokenId);
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).minimumBidAmount,
            auctionParams.minimumBidAmount
        );
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).buyoutBidAmount,
            auctionParams.buyoutBidAmount
        );
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).timeBufferInSeconds,
            auctionParams.timeBufferInSeconds
        );
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).bidBufferBps,
            auctionParams.bidBufferBps
        );
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).startTimestamp,
            auctionParams.startTimestamp
        );
        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).endTimestamp,
            auctionParams.endTimestamp
        );
        assertEq(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).auctionCreator, seller);
        assertEq(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).currency, auctionParams.currency);
        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).tokenType),
            uint256(IEnglishAuctions.TokenType.ERC721)
        );
        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(expectedAuctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }
}
