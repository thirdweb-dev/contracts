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
import { MockRoyaltyEngineV1 } from "../../../mocks/MockRoyaltyEngineV1.sol";
import { PlatformFee } from "contracts/extension/PlatformFee.sol";

import { IEnglishAuctions } from "contracts/prebuilts/marketplace/IMarketplace.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

contract ReentrantRecipient is ERC1155Holder {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        uint256 auctionId = 0;
        uint256 bidAmount = 10 ether;
        EnglishAuctionsLogic(msg.sender).bidInAuction(auctionId, bidAmount);
        return super.onERC1155Received(operator, from, id, value, data);
    }
}

contract EnglishAuctionsPayoutTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    // Auction parameters
    uint256 internal auctionId;
    uint256 internal bidAmount;
    address internal winningBidder = address(0x123);
    IEnglishAuctions.AuctionParameters internal auctionParams;

    // Events
    event NewBid(
        uint256 indexed auctionId,
        address indexed bidder,
        address indexed assetContract,
        uint256 bidAmount,
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
                    (marketplaceDeployer, "", new address[](0), platformFeeRecipient, uint16(platformFeeBps))
                )
            )
        );

        // Setup roles for seller and assets
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(0));
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), address(0));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        vm.stopPrank();

        vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");

        // Sample auction parameters.
        address assetContract = address(erc1155);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 minimumBidAmount = 1 ether;
        uint256 buyoutBidAmount = 100 ether;
        uint64 timeBufferInSeconds = 10 seconds;
        uint64 bidBufferBps = 1000;
        uint64 startTimestamp = 100 minutes;
        uint64 endTimestamp = 200 minutes;

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

        // Set bidAmount
        bidAmount = auctionParams.minimumBidAmount;

        // Mint NFT to seller.
        erc721.mint(seller, 1); // to, amount
        erc1155.mint(seller, 0, 100); // to, id, amount

        // Create auction
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        erc1155.setApprovalForAll(marketplace, true);
        auctionId = EnglishAuctionsLogic(marketplace).createAuction(auctionParams);
        vm.stopPrank();

        // Mint currency to bidder.
        erc20.mint(buyer, 10_000 ether);

        vm.prank(buyer);
        erc20.approve(marketplace, 100 ether);
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

    address payable[] internal mockRecipients;
    uint256[] internal mockAmounts;
    MockRoyaltyEngineV1 internal royaltyEngine;

    function _setupRoyaltyEngine() private {
        mockRecipients.push(payable(address(0x12345)));
        mockRecipients.push(payable(address(0x56789)));

        mockAmounts.push(10 ether);
        mockAmounts.push(15 ether);

        royaltyEngine = new MockRoyaltyEngineV1(mockRecipients, mockAmounts);
    }

    function test_payout_whenZeroRoyaltyRecipients() public {
        vm.warp(auctionParams.startTimestamp);
        vm.prank(buyer);
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.buyoutBidAmount);

        vm.prank(seller);
        EnglishAuctionsLogic(marketplace).collectAuctionPayout(auctionId);

        uint256 totalPrice = auctionParams.buyoutBidAmount;

        uint256 platformFees = (totalPrice * platformFeeBps) / 10_000;

        {
            // Platform fee recipient receives correct amount
            assertBalERC20Eq(address(erc20), platformFeeRecipient, platformFees);

            // Seller gets total price minus royalty amounts
            assertBalERC20Eq(address(erc20), seller, totalPrice - platformFees);
        }
    }

    modifier whenNonZeroRoyaltyRecipients() {
        _setupRoyaltyEngine();

        // Add RoyaltyEngine to marketplace
        vm.prank(marketplaceDeployer);
        RoyaltyPaymentsLogic(marketplace).setRoyaltyEngine(address(royaltyEngine));

        _;
    }

    function test_payout_whenInsufficientFundsToPayRoyaltyAfterPlatformFeePayout() public whenNonZeroRoyaltyRecipients {
        vm.prank(marketplaceDeployer);
        PlatformFee(marketplace).setPlatformFeeInfo(platformFeeRecipient, 9999); // 99.99% fees;

        // Buy tokens from listing.
        vm.warp(auctionParams.startTimestamp);
        vm.prank(buyer);
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.buyoutBidAmount);

        vm.prank(seller);
        vm.expectRevert("fees exceed the price");
        EnglishAuctionsLogic(marketplace).collectAuctionPayout(auctionId);
    }

    function test_payout_whenSufficientFundsToPayRoyaltyAfterPlatformFeePayout() public whenNonZeroRoyaltyRecipients {
        assertEq(RoyaltyPaymentsLogic(marketplace).getRoyaltyEngineAddress(), address(royaltyEngine));

        vm.warp(auctionParams.startTimestamp);
        vm.prank(buyer);
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.buyoutBidAmount);

        vm.prank(seller);
        EnglishAuctionsLogic(marketplace).collectAuctionPayout(auctionId);

        uint256 totalPrice = auctionParams.buyoutBidAmount;
        uint256 platformFees = (totalPrice * platformFeeBps) / 10_000;

        {
            // Royalty recipients receive correct amounts
            assertBalERC20Eq(address(erc20), mockRecipients[0], mockAmounts[0]);
            assertBalERC20Eq(address(erc20), mockRecipients[1], mockAmounts[1]);

            // Platform fee recipient receives correct amount
            assertBalERC20Eq(address(erc20), platformFeeRecipient, platformFees);

            // Seller gets total price minus royalty amounts
            assertBalERC20Eq(address(erc20), seller, totalPrice - mockAmounts[0] - mockAmounts[1] - platformFees);
        }
    }
}
