// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract MockTransferListingTokens is DirectListingsLogic {
    constructor(address _nativeTokenWrapper) DirectListingsLogic(_nativeTokenWrapper) {}

    function transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        IDirectListings.Listing memory _listing
    ) external {
        _transferListingTokens(_from, _to, _quantity, _listing);
    }
}

contract TransferListingTokensTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;
    address public recipient;

    // Default listing parameters
    IDirectListings.ListingParameters internal listingParams;
    uint256 listingId_erc721 = 0;
    uint256 listingId_erc1155 = 1;

    function setUp() public override {
        super.setUp();

        marketplaceDeployer = getActor(1);
        seller = getActor(2);
        recipient = getActor(3);

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

        // Setup roles
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(0));
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), address(0));

        vm.stopPrank();

        // Setup listing params
        address assetContract = address(erc721);
        uint256 tokenId = 0;
        uint256 quantity = 1;
        address currency = address(erc20);
        uint256 pricePerToken = 1 ether;
        uint128 startTimestamp = 100;
        uint128 endTimestamp = 200;
        bool reserved = true;

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

        // Mint 1 ERC721 NFT to seller
        erc721.mint(seller, listingParams.quantity);
        // Mint 100 ERC1155 NFT to seller
        erc1155.mint(seller, listingParams.tokenId, 100);

        vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");

        // Create listings
        vm.startPrank(marketplaceDeployer);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        vm.stopPrank();

        vm.startPrank(seller);

        erc721.setApprovalForAll(marketplace, true);
        erc1155.setApprovalForAll(marketplace, true);

        listingId_erc721 = DirectListingsLogic(marketplace).createListing(listingParams);

        listingParams.assetContract = address(erc1155);
        listingParams.quantity = 100;
        listingId_erc1155 = DirectListingsLogic(marketplace).createListing(listingParams);

        vm.stopPrank();
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `MockTransferListingTokens`
        address directListings = address(new MockTransferListingTokens(address(weth)));
        vm.label(directListings, "DirectListings_Extension");

        // Extension: DirectListingsLogic
        Extension memory extension_directListings;
        extension_directListings.metadata = ExtensionMetadata({
            name: "MockTransferListingTokens",
            metadataURI: "ipfs://MockTransferListingTokens",
            implementation: directListings
        });

        extension_directListings.functions = new ExtensionFunction[](3);
        extension_directListings.functions[0] = ExtensionFunction(
            MockTransferListingTokens.transferListingTokens.selector,
            "transferListingTokens(address,address,uint256,(uint256,uint256,uint256,uint256,uint128,uint128,address,address,address,uint8,uint8,bool))"
        );
        extension_directListings.functions[1] = ExtensionFunction(
            DirectListingsLogic.createListing.selector,
            "createListing((address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extension_directListings.functions[2] = ExtensionFunction(
            DirectListingsLogic.getListing.selector,
            "getListing(uint256)"
        );
        extensions[0] = extension_directListings;
    }

    function test_transferListingTokens_erc1155() public {
        IDirectListings.Listing memory listing = DirectListingsLogic(marketplace).getListing(listingId_erc1155);

        assertEq(erc1155.balanceOf(seller, listing.tokenId), 100);
        assertEq(erc1155.balanceOf(recipient, listing.tokenId), 0);

        MockTransferListingTokens(marketplace).transferListingTokens(seller, recipient, 100, listing);

        assertEq(erc1155.balanceOf(seller, listing.tokenId), 0);
        assertEq(erc1155.balanceOf(recipient, listing.tokenId), 100);
    }

    function test_transferListingTokens_erc721() public {
        IDirectListings.Listing memory listing = DirectListingsLogic(marketplace).getListing(listingId_erc721);

        assertEq(erc721.ownerOf(listing.tokenId), seller);

        MockTransferListingTokens(marketplace).transferListingTokens(seller, recipient, 1, listing);

        assertEq(erc721.ownerOf(listing.tokenId), recipient);
    }
}
