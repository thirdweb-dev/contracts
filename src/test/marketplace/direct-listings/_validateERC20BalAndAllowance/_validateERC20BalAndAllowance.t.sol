// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { MarketplaceV3 } from "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol";
import { IDirectListings } from "contracts/prebuilts/marketplace/IMarketplace.sol";

contract MockValidateERC20BalAndAllowance is DirectListingsLogic {
    constructor(address _nativeTokenWrapper) DirectListingsLogic(_nativeTokenWrapper) {}

    function validateERC20BalAndAllowance(
        address _tokenOwner,
        address _currency,
        uint256 _amount
    ) external returns (bool) {
        _validateERC20BalAndAllowance(_tokenOwner, _currency, _amount);
        return true;
    }
}

contract ValidateERC20BalAndAllowanceTest is BaseTest, IExtension {
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
        // Mint some ERC20 tokens to seller
        erc20.mint(seller, 100 ether);

        vm.label(impl, "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](1);

        // Deploy `MockValidateERC20BalAndAllowance`
        address directListings = address(new MockValidateERC20BalAndAllowance(address(weth)));
        vm.label(directListings, "DirectListings_Extension");

        // Extension: DirectListingsLogic
        Extension memory extension_directListings;
        extension_directListings.metadata = ExtensionMetadata({
            name: "MockValidateERC20BalAndAllowance",
            metadataURI: "ipfs://MockValidateERC20BalAndAllowance",
            implementation: directListings
        });

        extension_directListings.functions = new ExtensionFunction[](1);
        extension_directListings.functions[0] = ExtensionFunction(
            MockValidateERC20BalAndAllowance.validateERC20BalAndAllowance.selector,
            "validateERC20BalAndAllowance(address,address,uint256)"
        );
        extensions[0] = extension_directListings;
    }

    function test_validateERC20BalAndAllowance_whenInsufficientTokensOwned() public {
        vm.startPrank(seller);

        erc20.approve(marketplace, 100 ether);
        erc20.burn(1 ether);

        vm.stopPrank();

        vm.expectRevert("!BAL20");
        MockValidateERC20BalAndAllowance(marketplace).validateERC20BalAndAllowance(seller, address(erc20), 100 ether);
    }

    function test_validateERC20BalAndAllowance_whenTokensNotApprovedToTransfer() public {
        vm.startPrank(seller);
        erc20.approve(marketplace, 0);
        vm.stopPrank();

        vm.expectRevert("!BAL20");
        MockValidateERC20BalAndAllowance(marketplace).validateERC20BalAndAllowance(seller, address(erc20), 100 ether);
    }

    function test_validateERC20BalAndAllowance_whenTokensOwnedAndApproved() public {
        vm.prank(seller);
        erc20.approve(marketplace, 100 ether);

        bool result = MockValidateERC20BalAndAllowance(marketplace).validateERC20BalAndAllowance(
            seller,
            address(erc20),
            100 ether
        );
        assertEq(result, true);
    }
}
