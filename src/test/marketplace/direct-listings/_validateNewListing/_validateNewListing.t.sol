// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract MockValidateListing is DirectListingsLogic {
    constructor(address _nativeTokenWrapper) DirectListingsLogic(_nativeTokenWrapper) {}

    function validateNewListing(ListingParameters memory _params, TokenType _tokenType) external returns (bool) {
        _validateNewListing(_params, _tokenType);
        return true;
    }
}

contract ValidateNewListingTest is BaseTest, IExtension {
    // Target contract
    address public marketplace;

    // Participants
    address public marketplaceDeployer;
    address public seller;

    // Default listing parameters
    IDirectListings.ListingParameters internal listingParams;

    function setUp() public override {
        super.setUp();

        marketplaceDeployer = getActor(1);
        seller = getActor(2);

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
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `MockValidateListing`
        address directListings = address(new MockValidateListing(address(weth)));
        vm.label(directListings, "DirectListings_Extension");

        // Extension: DirectListingsLogic
        Extension memory extension_directListings;
        extension_directListings.metadata = ExtensionMetadata({
            name: "MockValidateListing",
            metadataURI: "ipfs://MockValidateListing",
            implementation: directListings
        });

        extension_directListings.functions = new ExtensionFunction[](1);
        extension_directListings.functions[0] = ExtensionFunction(
            MockValidateListing.validateNewListing.selector,
            "validateNewListing((address,uint256,uint256,address,uint256,uint128,uint128,bool),uint8)"
        );
        extensions[0] = extension_directListings;
    }

    function test_validateNewListing_whenQuantityIsZero() public {
        listingParams.quantity = 0;

        vm.expectRevert("Marketplace: listing zero quantity.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC721);
    }

    modifier whenQuantityIsOne() {
        listingParams.quantity = 1;
        _;
    }

    modifier whenQuantityIsGtOne() {
        listingParams.quantity = 2;
        _;
    }

    modifier whenTokenIsERC721() {
        listingParams.assetContract = address(erc721);
        _;
    }

    modifier whenTokenIsERC1155() {
        listingParams.assetContract = address(erc1155);
        _;
    }

    function test_validateNewListing_whenTokenIsERC721() public whenQuantityIsGtOne {
        vm.expectRevert("Marketplace: listing invalid quantity.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC721);
    }

    function test_validateNewListing_whenTokenOwnerDoesntOwnSufficientTokens_1()
        public
        whenQuantityIsGtOne
        whenTokenIsERC1155
    {
        vm.startPrank(seller);
        erc1155.setApprovalForAll(marketplace, true);
        erc1155.burn(seller, listingParams.tokenId, 100);
        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC1155);
    }

    modifier whenTokenOwnerOwnsSufficientTokens() {
        _;
    }

    function test_validateNewListing_whenTokensNotApprovedForTransfer_1()
        public
        whenQuantityIsGtOne
        whenTokenIsERC1155
        whenTokenOwnerOwnsSufficientTokens
    {
        vm.prank(seller);
        erc1155.setApprovalForAll(marketplace, false);

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC1155);
    }

    modifier whenTokensApprovedForTransfer(IDirectListings.TokenType tokenType) {
        vm.prank(seller);
        if (tokenType == IDirectListings.TokenType.ERC721) {
            erc721.setApprovalForAll(marketplace, true);
        } else {
            erc1155.setApprovalForAll(marketplace, true);
        }
        _;
    }

    function test_validateNewListing_whenTokensOwnedAndApproved_1()
        public
        whenQuantityIsGtOne
        whenTokenIsERC1155
        whenTokenOwnerOwnsSufficientTokens
        whenTokensApprovedForTransfer(IDirectListings.TokenType.ERC1155)
    {
        vm.prank(seller);
        assertEq(
            MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC1155),
            true
        );
    }

    function test_validateNewListing_whenTokenOwnerDoesntOwnSufficientTokens_2a()
        public
        whenQuantityIsOne
        whenTokenIsERC1155
    {
        vm.startPrank(seller);
        erc1155.setApprovalForAll(marketplace, true);
        erc1155.burn(seller, listingParams.tokenId, 100);
        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC1155);
    }

    function test_validateNewListing_whenTokenOwnerDoesntOwnSufficientTokens_2b()
        public
        whenQuantityIsOne
        whenTokenIsERC721
    {
        vm.startPrank(seller);
        erc721.setApprovalForAll(marketplace, true);
        erc721.burn(listingParams.tokenId);
        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC721);
    }

    function test_validateNewListing_whenTokensNotApprovedForTransfer_2a()
        public
        whenQuantityIsOne
        whenTokenIsERC721
        whenTokenOwnerOwnsSufficientTokens
    {
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, false);

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC721);
    }

    function test_validateNewListing_whenTokensNotApprovedForTransfer_2b()
        public
        whenQuantityIsOne
        whenTokenIsERC1155
        whenTokenOwnerOwnsSufficientTokens
    {
        vm.prank(seller);
        erc1155.setApprovalForAll(marketplace, false);

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC1155);
    }

    function test_validateNewListing_whenTokensOwnedAndApproved_2a()
        public
        whenQuantityIsOne
        whenTokenIsERC1155
        whenTokenOwnerOwnsSufficientTokens
        whenTokensApprovedForTransfer(IDirectListings.TokenType.ERC1155)
    {
        vm.prank(seller);
        assertEq(
            MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC1155),
            true
        );
    }

    function test_validateNewListing_whenTokensOwnedAndApproved_2b()
        public
        whenQuantityIsOne
        whenTokenIsERC721
        whenTokenOwnerOwnsSufficientTokens
        whenTokensApprovedForTransfer(IDirectListings.TokenType.ERC721)
    {
        vm.prank(seller);
        assertEq(
            MockValidateListing(marketplace).validateNewListing(listingParams, IDirectListings.TokenType.ERC721),
            true
        );
    }
}
