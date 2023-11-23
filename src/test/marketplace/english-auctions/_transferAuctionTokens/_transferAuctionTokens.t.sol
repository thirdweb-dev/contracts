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

contract MockTransferAuctionTokens is EnglishAuctionsLogic {
    constructor(address _nativeTokenWrapper) EnglishAuctionsLogic(_nativeTokenWrapper) {}

    function transferAuctionTokens(address _from, address _to, Auction memory _auction) external {
        _transferAuctionTokens(_from, _to, _auction);
    }
}

contract TransferAuctionTokensTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public buyer;

    // Auction parameters
    uint256 internal auctionId_erc1155;
    uint256 internal auctionId_erc721;
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
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
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

        auctionId_erc1155 = EnglishAuctionsLogic(marketplace).createAuction(auctionParams);

        auctionParams.assetContract = address(erc721);
        auctionId_erc721 = EnglishAuctionsLogic(marketplace).createAuction(auctionParams);

        vm.stopPrank();

        // Mint currency to bidder.
        erc20.mint(buyer, 10_000 ether);

        vm.prank(buyer);
        erc20.approve(marketplace, 100 ether);
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `EnglishAuctions`
        address englishAuctions = address(new MockTransferAuctionTokens(address(weth)));
        vm.label(englishAuctions, "EnglishAuctions_Extension");

        // Extension: EnglishAuctionsLogic
        Extension memory extension_englishAuctions;
        extension_englishAuctions.metadata = ExtensionMetadata({
            name: "EnglishAuctionsLogic",
            metadataURI: "ipfs://EnglishAuctions",
            implementation: englishAuctions
        });

        extension_englishAuctions.functions = new ExtensionFunction[](3);
        extension_englishAuctions.functions[0] = ExtensionFunction(
            MockTransferAuctionTokens.transferAuctionTokens.selector,
            "transferAuctionTokens(address,address,(uint256,uint256,uint256,uint256,uint256,uint64,uint64,uint64,uint64,address,address,address,uint8,uint8))"
        );
        extension_englishAuctions.functions[1] = ExtensionFunction(
            EnglishAuctionsLogic.createAuction.selector,
            "createAuction((address,uint256,uint256,address,uint256,uint256,uint64,uint64,uint64,uint64))"
        );
        extension_englishAuctions.functions[2] = ExtensionFunction(
            EnglishAuctionsLogic.getAuction.selector,
            "getAuction(uint256)"
        );

        extensions[0] = extension_englishAuctions;
    }

    function test_transferAuctionTokens_erc1155() public {
        IEnglishAuctions.Auction memory auction = EnglishAuctionsLogic(marketplace).getAuction(auctionId_erc1155);

        assertEq(erc1155.balanceOf(address(marketplace), auction.tokenId), 1);
        assertEq(erc1155.balanceOf(buyer, auction.tokenId), 0);

        MockTransferAuctionTokens(marketplace).transferAuctionTokens(address(marketplace), buyer, auction);

        assertEq(erc1155.balanceOf(address(marketplace), auction.tokenId), 0);
        assertEq(erc1155.balanceOf(buyer, auction.tokenId), 1);
    }

    function test_transferAuctionTokens_erc721() public {
        IEnglishAuctions.Auction memory auction = EnglishAuctionsLogic(marketplace).getAuction(auctionId_erc721);

        assertEq(erc721.ownerOf(auction.tokenId), address(marketplace));

        MockTransferAuctionTokens(marketplace).transferAuctionTokens(address(marketplace), buyer, auction);

        assertEq(erc721.ownerOf(auction.tokenId), buyer);
    }
}
