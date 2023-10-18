// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract MockValidateOwnershipAndApproval is DirectListingsLogic {
    constructor(address _nativeTokenWrapper) DirectListingsLogic(_nativeTokenWrapper) {}

    function validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) external view returns (bool) {
        return _validateOwnershipAndApproval(_tokenOwner, _assetContract, _tokenId, _quantity, _tokenType);
    }
}

contract ValidateOwnershipAndApprovalTest is BaseTest, IExtension {
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
        address directListings = address(new MockValidateOwnershipAndApproval(address(weth)));
        vm.label(directListings, "DirectListings_Extension");

        // Extension: DirectListingsLogic
        Extension memory extension_directListings;
        extension_directListings.metadata = ExtensionMetadata({
            name: "MockValidateOwnershipAndApproval",
            metadataURI: "ipfs://MockValidateOwnershipAndApproval",
            implementation: directListings
        });

        extension_directListings.functions = new ExtensionFunction[](1);
        extension_directListings.functions[0] = ExtensionFunction(
            MockValidateOwnershipAndApproval.validateOwnershipAndApproval.selector,
            "validateOwnershipAndApproval(address,address,uint256,uint256,uint8)"
        );
        extensions[0] = extension_directListings;
    }

    modifier whenTokenIsERC1155() {
        listingParams.assetContract = address(erc1155);
        listingParams.quantity = 100;
        _;
    }

    modifier whenTokenIsERC721() {
        listingParams.assetContract = address(erc721);
        listingParams.quantity = 1;
        _;
    }

    function test_validateOwnershipAndApproval_whenInsufficientTokensOwned_erc1155() public whenTokenIsERC1155 {
        vm.prank(seller);
        erc1155.setApprovalForAll(marketplace, true);

        vm.prank(seller);
        erc1155.burn(seller, listingParams.tokenId, 100);

        bool result = MockValidateOwnershipAndApproval(marketplace).validateOwnershipAndApproval(
            seller,
            listingParams.assetContract,
            listingParams.tokenId,
            listingParams.quantity,
            IDirectListings.TokenType.ERC1155
        );
        assertEq(result, false);
    }

    function test_validateOwnershipAndApproval_whenInsufficientTokensOwned_erc721() public whenTokenIsERC721 {
        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, true);

        vm.prank(seller);
        erc721.burn(listingParams.tokenId);

        bool result = MockValidateOwnershipAndApproval(marketplace).validateOwnershipAndApproval(
            seller,
            listingParams.assetContract,
            listingParams.tokenId,
            listingParams.quantity,
            IDirectListings.TokenType.ERC721
        );
        assertEq(result, false);
    }

    modifier whenSufficientTokensOwned() {
        _;
    }

    function test_validateOwnershipAndApproval_whenTokensNotApprovedToTransfer_erc1155()
        public
        whenTokenIsERC1155
        whenSufficientTokensOwned
    {
        assertEq(erc1155.balanceOf(seller, listingParams.tokenId), listingParams.quantity);

        vm.prank(seller);
        erc1155.setApprovalForAll(marketplace, false);

        bool result = MockValidateOwnershipAndApproval(marketplace).validateOwnershipAndApproval(
            seller,
            listingParams.assetContract,
            listingParams.tokenId,
            listingParams.quantity,
            IDirectListings.TokenType.ERC1155
        );
        assertEq(result, false);
    }

    function test_validateOwnershipAndApproval_whenTokensNotApprovedToTransfer_erc721()
        public
        whenTokenIsERC721
        whenSufficientTokensOwned
    {
        assertEq(erc721.ownerOf(listingParams.tokenId), seller);

        vm.prank(seller);
        erc721.setApprovalForAll(marketplace, false);

        bool result = MockValidateOwnershipAndApproval(marketplace).validateOwnershipAndApproval(
            seller,
            listingParams.assetContract,
            listingParams.tokenId,
            listingParams.quantity,
            IDirectListings.TokenType.ERC721
        );
        assertEq(result, false);
    }

    modifier whenTokensApprovedForTransfer(IDirectListings.TokenType tokenType) {
        vm.prank(seller);
        if (tokenType == IDirectListings.TokenType.ERC1155) {
            erc1155.setApprovalForAll(marketplace, true);
        } else {
            erc721.setApprovalForAll(marketplace, true);
        }
        _;
    }

    function test_validateOwnershipAndApproval_whenTokensOwnedAndApproved_erc1155()
        public
        whenTokenIsERC1155
        whenSufficientTokensOwned
        whenTokensApprovedForTransfer(IDirectListings.TokenType.ERC1155)
    {
        bool result = MockValidateOwnershipAndApproval(marketplace).validateOwnershipAndApproval(
            seller,
            listingParams.assetContract,
            listingParams.tokenId,
            listingParams.quantity,
            IDirectListings.TokenType.ERC1155
        );
        assertEq(result, true);
    }

    function test_validateOwnershipAndApproval_whenTokensOwnedAndApproved_erc721()
        public
        whenTokenIsERC721
        whenSufficientTokensOwned
        whenTokensApprovedForTransfer(IDirectListings.TokenType.ERC721)
    {
        bool result = MockValidateOwnershipAndApproval(marketplace).validateOwnershipAndApproval(
            seller,
            listingParams.assetContract,
            listingParams.tokenId,
            listingParams.quantity,
            IDirectListings.TokenType.ERC721
        );
        assertEq(result, true);
    }
}
