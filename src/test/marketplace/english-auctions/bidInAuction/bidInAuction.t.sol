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

contract BidInAuctionTest is BaseTest, IExtension {
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
                    (marketplaceDeployer, "", new address[](0), marketplaceDeployer, 0)
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
        uint256 buyoutBidAmount = 10 ether;
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

    function test_bidInAuction_callIsReentrant() public {
        vm.warp(auctionParams.startTimestamp + 1);
        address reentrantRecipient = address(new ReentrantRecipient());

        erc20.mint(reentrantRecipient, 100 ether);

        vm.prank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), reentrantRecipient);

        vm.startPrank(reentrantRecipient);
        erc20.approve(marketplace, 100 ether);
        vm.expectRevert();
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.buyoutBidAmount);
        vm.stopPrank();
    }

    modifier whenCallIsNotReentrant() {
        _;
    }

    function test_bidInAuction_whenAuctionDoesNotExist() public whenCallIsNotReentrant {
        vm.prank(buyer);
        vm.expectRevert("Marketplace: invalid auction.");
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId + 1, bidAmount);
    }

    modifier whenAuctionExists() {
        _;
    }

    function test_bidInAuction_whenAuctionIsNotActive() public whenCallIsNotReentrant whenAuctionExists {
        vm.prank(buyer);
        vm.expectRevert("Marketplace: inactive auction.");
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);
    }

    modifier whenAuctionIsActive() {
        vm.warp(auctionParams.startTimestamp + 1);
        _;
    }

    function test_bidInAuction_whenBidAmountIsZero()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
    {
        vm.prank(buyer);
        vm.expectRevert("Marketplace: Bidding with zero amount.");
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, 0);
    }

    modifier whenBidAmountIsNotZero() {
        bidAmount = auctionParams.minimumBidAmount;
        _;
    }

    function test_bidInAuction_whenAuctionCurrencyIsERC20AndMsgValueSent()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
    {
        vm.deal(buyer, 1 ether);

        vm.prank(buyer);
        vm.expectRevert("Marketplace: invalid native tokens sent.");
        EnglishAuctionsLogic(marketplace).bidInAuction{ value: 1 }(auctionId, auctionParams.buyoutBidAmount);
    }

    function test_bidInAuction_whenBidAmountIsGtBuyoutPrice()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
    {
        vm.prank(buyer);
        vm.expectRevert("Marketplace: Bidding above buyout price.");
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.buyoutBidAmount + 1);
    }

    modifier whenBidAmountLtBuyoutPrice() {
        bidAmount = auctionParams.buyoutBidAmount - 1;
        _;
    }

    modifier whenBidAmountEqBuyoutPrice() {
        bidAmount = auctionParams.buyoutBidAmount;
        _;
    }

    modifier whenCurrentWinningBid() {
        // Existing winning bid.
        erc20.mint(winningBidder, 100 ether);

        vm.prank(winningBidder);
        erc20.approve(marketplace, 100 ether);

        vm.prank(winningBidder);
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.minimumBidAmount + 1);
        _;
    }

    modifier whenNoCurrentWinningBid() {
        _;
    }

    function test_bidInAuction_buyoutAndExistingWinningBid()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
        whenBidAmountEqBuyoutPrice
        whenCurrentWinningBid
    {
        uint256 winningBidderBal = erc20.balanceOf(winningBidder);

        assertEq(erc20.balanceOf(marketplace), auctionParams.minimumBidAmount + 1);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );

        vm.prank(buyer);
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);

        assertEq(erc20.balanceOf(winningBidder), winningBidderBal + auctionParams.minimumBidAmount + 1);
        assertEq(erc20.balanceOf(marketplace), bidAmount);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        // Auction is marked CLOSED in auction state when creator collected payout
        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }

    function test_bidInAuction_buyoutAndNoWinningBid()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
        whenBidAmountEqBuyoutPrice
        whenNoCurrentWinningBid
    {
        assertEq(erc20.balanceOf(marketplace), 0);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );

        vm.prank(buyer);
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);

        assertEq(erc20.balanceOf(marketplace), bidAmount);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        // Auction is marked CLOSED in auction state when creator collected payout
        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }

    function test_bidInAuction_whenBidIsNotNewWinningBid()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenCurrentWinningBid
        whenBidAmountIsNotZero
        whenBidAmountLtBuyoutPrice
    {
        assertEq(EnglishAuctionsLogic(marketplace).isNewWinningBid(auctionId, auctionParams.minimumBidAmount), false);

        vm.prank(buyer);
        vm.expectRevert("Marketplace: not winning bid.");
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, auctionParams.minimumBidAmount);
    }

    modifier whenBidIsNewWinningBig() {
        bidAmount = auctionParams.buyoutBidAmount - 1;
        assertEq(EnglishAuctionsLogic(marketplace).isNewWinningBid(auctionId, bidAmount), true);
        _;
    }

    modifier whenBidWithinTimeBuffer() {
        vm.warp(auctionParams.endTimestamp - auctionParams.timeBufferInSeconds);
        _;
    }

    function test_bidInAuction_noBuyoutAndExistingWinningBid()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
        whenBidAmountLtBuyoutPrice
        whenBidIsNewWinningBig
        whenCurrentWinningBid
    {
        uint256 winningBidderBal = erc20.balanceOf(winningBidder);

        assertEq(erc20.balanceOf(marketplace), auctionParams.minimumBidAmount + 1);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );

        (address bidderBefore, address currencyBefore, uint256 bidAmountBefore) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderBefore, winningBidder);
        assertEq(currencyBefore, address(erc20));
        assertEq(bidAmountBefore, auctionParams.minimumBidAmount + 1);

        assertEq(EnglishAuctionsLogic(marketplace).isNewWinningBid(auctionId, bidAmount), true);

        vm.startPrank(buyer);
        vm.expectEmit(true, true, true, false);
        emit NewBid(
            auctionId,
            buyer,
            address(erc1155),
            bidAmount,
            EnglishAuctionsLogic(marketplace).getAuction(auctionId)
        );
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);
        vm.stopPrank();

        (address bidderAfter, address currencyAfter, uint256 bidAmountAfter) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderAfter, buyer);
        assertEq(currencyAfter, address(erc20));
        assertEq(bidAmountAfter, bidAmount);

        assertEq(erc20.balanceOf(winningBidder), winningBidderBal + auctionParams.minimumBidAmount + 1);
        assertEq(erc20.balanceOf(marketplace), bidAmount);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        // Auction is marked CLOSED in auction state when creator collected payout
        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }

    function test_bidInAuction_noBuyoutAndNoWinningBid()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
        whenBidAmountLtBuyoutPrice
        whenBidIsNewWinningBig
        whenNoCurrentWinningBid
    {
        assertEq(erc20.balanceOf(marketplace), 0);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );

        (address bidderBefore, address currencyBefore, uint256 bidAmountBefore) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderBefore, address(0));
        assertEq(currencyBefore, address(erc20));
        assertEq(bidAmountBefore, 0);

        vm.startPrank(buyer);
        vm.expectEmit(true, true, true, false);
        emit NewBid(
            auctionId,
            buyer,
            address(erc1155),
            bidAmount,
            EnglishAuctionsLogic(marketplace).getAuction(auctionId)
        );
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);
        vm.stopPrank();

        (address bidderAfter, address currencyAfter, uint256 bidAmountAfter) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderAfter, buyer);
        assertEq(currencyAfter, address(erc20));
        assertEq(bidAmountAfter, bidAmount);

        assertEq(erc20.balanceOf(marketplace), bidAmount);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }

    function test_bidInAuction_noBuyoutAndExistingWinningBid_withinTimeBuffer()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
        whenBidAmountLtBuyoutPrice
        whenBidIsNewWinningBig
        whenCurrentWinningBid
        whenBidWithinTimeBuffer
    {
        uint256 winningBidderBal = erc20.balanceOf(winningBidder);

        assertEq(erc20.balanceOf(marketplace), auctionParams.minimumBidAmount + 1);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );

        (address bidderBefore, address currencyBefore, uint256 bidAmountBefore) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderBefore, winningBidder);
        assertEq(currencyBefore, address(erc20));
        assertEq(bidAmountBefore, auctionParams.minimumBidAmount + 1);

        assertEq(EnglishAuctionsLogic(marketplace).getAuction(auctionId).endTimestamp, auctionParams.endTimestamp);

        vm.startPrank(buyer);
        vm.expectEmit(true, true, true, false);
        emit NewBid(
            auctionId,
            buyer,
            address(erc1155),
            bidAmount,
            EnglishAuctionsLogic(marketplace).getAuction(auctionId)
        );
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);
        vm.stopPrank();

        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(auctionId).endTimestamp,
            auctionParams.endTimestamp + auctionParams.timeBufferInSeconds
        );

        (address bidderAfter, address currencyAfter, uint256 bidAmountAfter) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderAfter, buyer);
        assertEq(currencyAfter, address(erc20));
        assertEq(bidAmountAfter, bidAmount);

        assertEq(erc20.balanceOf(winningBidder), winningBidderBal + auctionParams.minimumBidAmount + 1);
        assertEq(erc20.balanceOf(marketplace), bidAmount);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        // Auction is marked CLOSED in auction state when creator collected payout
        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }

    function test_bidInAuction_noBuyoutAndNoWinningBid_withinTimeBuffer()
        public
        whenCallIsNotReentrant
        whenAuctionExists
        whenAuctionIsActive
        whenBidAmountIsNotZero
        whenBidAmountLtBuyoutPrice
        whenBidIsNewWinningBig
        whenBidWithinTimeBuffer
        whenNoCurrentWinningBid
    {
        assertEq(erc20.balanceOf(marketplace), 0);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );

        (address bidderBefore, address currencyBefore, uint256 bidAmountBefore) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderBefore, address(0));
        assertEq(currencyBefore, address(erc20));
        assertEq(bidAmountBefore, 0);

        assertEq(EnglishAuctionsLogic(marketplace).getAuction(auctionId).endTimestamp, auctionParams.endTimestamp);

        vm.startPrank(buyer);
        vm.expectEmit(true, true, true, false);
        emit NewBid(
            auctionId,
            buyer,
            address(erc1155),
            bidAmount,
            EnglishAuctionsLogic(marketplace).getAuction(auctionId)
        );
        EnglishAuctionsLogic(marketplace).bidInAuction(auctionId, bidAmount);
        vm.stopPrank();

        assertEq(
            EnglishAuctionsLogic(marketplace).getAuction(auctionId).endTimestamp,
            auctionParams.endTimestamp + auctionParams.timeBufferInSeconds
        );

        (address bidderAfter, address currencyAfter, uint256 bidAmountAfter) = EnglishAuctionsLogic(marketplace)
            .getWinningBid(auctionId);

        assertEq(bidderAfter, buyer);
        assertEq(currencyAfter, address(erc20));
        assertEq(bidAmountAfter, bidAmount);

        assertEq(erc20.balanceOf(marketplace), bidAmount);

        assertEq(erc1155.balanceOf(marketplace, auctionParams.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auctionParams.tokenId), 0);
        assertEq(erc1155.balanceOf(seller, auctionParams.tokenId), 99);

        assertEq(
            uint256(EnglishAuctionsLogic(marketplace).getAuction(auctionId).status),
            uint256(IEnglishAuctions.Status.CREATED)
        );
    }
}
