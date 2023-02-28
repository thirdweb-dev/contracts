// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test helper imports
import { BaseTest, IERC721Receiver } from "../utils/BaseTest.sol";

// Test contracts and interfaces
import "lib/dynamic-contracts/src/interface/IExtension.sol";
import { ExtensionRegistry } from "contracts/dynamic-contracts/ExtensionRegistry.sol";
import { TWRouter } from "contracts/dynamic-contracts/TWRouter.sol";
import { MarketplaceV3 } from "contracts/marketplace/entrypoint/MarketplaceV3.sol";
import { DirectListingsLogic } from "contracts/marketplace/direct-listings/DirectListingsLogic.sol";
import { TWProxy } from "contracts/TWProxy.sol";

import { PermissionsEnumerableImpl, PermissionsEnumerable, Permissions } from "contracts/dynamic-contracts/impl/PermissionsEnumerableImpl.sol";
import { MetaTx } from "contracts/dynamic-contracts/impl/MetaTx.sol";
import "contracts/openzeppelin-presets/metatx/ERC2771Context.sol";
import "contracts/dynamic-contracts/impl/ContractMetadataImpl.sol";
import "contracts/dynamic-contracts/impl/PlatformFeeImpl.sol";

import { IDirectListings } from "contracts/marketplace/IMarketplace.sol";

contract MarketplaceDirectListingsTest is BaseTest {
    address private registryDeployer;

    ExtensionRegistry private extensionRegistry;

    mapping(uint256 => IExtension.Extension) private extensions;

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
        registryDeployer = getActor(4);

        vm.prank(registryDeployer);
        extensionRegistry = new ExtensionRegistry(registryDeployer);

        setupMarketplace(adminDeployer, marketplaceDeployer);
    }

    function setupMarketplace(address _adminDeployer, address _marketplaceDeployer) private {
        string[] memory extensionNames = new string[](5);

        // Deploy extensions

        // Extension: ERC2771Context
        address erc2771Context = address(new MetaTx(forwarders()));

        extensions[0].metadata = IExtension.ExtensionMetadata({
            name: "ERC2771Context",
            metadataURI: "ipfs://ERC2771Context",
            implementation: erc2771Context
        });

        extensions[0].functions.push(
            IExtension.ExtensionFunction(ERC2771Context.isTrustedForwarder.selector, "isTrustedForwarder(address)")
        );
        extensionNames[0] = extensions[0].metadata.name;

        // Extension: PermissionsEnumerable
        address permissions = address(new PermissionsEnumerableImpl());

        extensions[1].metadata = IExtension.ExtensionMetadata({
            name: "PermissionsEnumerable",
            metadataURI: "ipfs://PermissionsEnumerable",
            implementation: permissions
        });

        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.hasRole.selector, "hasRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.hasRoleWithSwitch.selector, "hasRoleWithSwitch(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.getRoleAdmin.selector, "getRoleAdmin(bytes32)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.grantRole.selector, "grantRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.revokeRole.selector, "revokeRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.renounceRole.selector, "renounceRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(PermissionsEnumerable.getRoleMember.selector, "getRoleMember(bytes32,uint256)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(
                PermissionsEnumerable.getRoleMemberCount.selector,
                "getRoleMemberCount(bytes32)"
            )
        );
        extensionNames[1] = extensions[1].metadata.name;

        // Extension: ContractMetadata
        address contractMetadata = address(new ContractMetadataImpl());

        extensions[2].metadata = IExtension.ExtensionMetadata({
            name: "ContractMetadata",
            metadataURI: "ipfs://ContractMetadata",
            implementation: contractMetadata
        });

        extensions[2].functions.push(
            IExtension.ExtensionFunction(ContractMetadata.contractURI.selector, "contractURI()")
        );
        extensions[2].functions.push(
            IExtension.ExtensionFunction(ContractMetadata.setContractURI.selector, "setContractURI(string)")
        );
        extensionNames[2] = extensions[2].metadata.name;

        // Extension: PlatformFee
        address platformFee = address(new PlatformFeeImpl());

        extensions[3].metadata = IExtension.ExtensionMetadata({
            name: "PlatformFee",
            metadataURI: "ipfs://PlatformFee",
            implementation: platformFee
        });

        extensions[3].functions.push(
            IExtension.ExtensionFunction(PlatformFee.getPlatformFeeInfo.selector, "getPlatformFeeInfo()")
        );
        extensions[3].functions.push(
            IExtension.ExtensionFunction(PlatformFee.setPlatformFeeInfo.selector, "setPlatformFeeInfo(address,uint256)")
        );
        extensionNames[3] = extensions[3].metadata.name;

        // [1] Index `DirectListings` functions in `Extension`
        extensions[4].metadata = IExtension.ExtensionMetadata({
            name: "DirectListingsLogic",
            metadataURI: "ipfs://direct",
            implementation: address(new DirectListingsLogic(address(weth)))
        });
        extensionNames[4] = extensions[4].metadata.name;

        IExtension.ExtensionFunction[] memory extensionFunctions = new IExtension.ExtensionFunction[](13);
        extensionFunctions[0] = IExtension.ExtensionFunction(
            DirectListingsLogic.totalListings.selector,
            "totalListings()"
        );
        extensionFunctions[1] = IExtension.ExtensionFunction(
            DirectListingsLogic.isBuyerApprovedForListing.selector,
            "isBuyerApprovedForListing(uint256,address)"
        );
        extensionFunctions[2] = IExtension.ExtensionFunction(
            DirectListingsLogic.isCurrencyApprovedForListing.selector,
            "isCurrencyApprovedForListing(uint256,address)"
        );
        extensionFunctions[3] = IExtension.ExtensionFunction(
            DirectListingsLogic.currencyPriceForListing.selector,
            "currencyPriceForListing(uint256,address)"
        );
        extensionFunctions[4] = IExtension.ExtensionFunction(
            DirectListingsLogic.createListing.selector,
            "createListing((address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extensionFunctions[5] = IExtension.ExtensionFunction(
            DirectListingsLogic.updateListing.selector,
            "updateListing(uint256,(address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extensionFunctions[6] = IExtension.ExtensionFunction(
            DirectListingsLogic.cancelListing.selector,
            "cancelListing(uint256)"
        );
        extensionFunctions[7] = IExtension.ExtensionFunction(
            DirectListingsLogic.approveBuyerForListing.selector,
            "approveBuyerForListing(uint256,address,bool)"
        );
        extensionFunctions[8] = IExtension.ExtensionFunction(
            DirectListingsLogic.approveCurrencyForListing.selector,
            "approveCurrencyForListing(uint256,address,uint256)"
        );
        extensionFunctions[9] = IExtension.ExtensionFunction(
            DirectListingsLogic.buyFromListing.selector,
            "buyFromListing(uint256,address,uint256,address,uint256)"
        );
        extensionFunctions[10] = IExtension.ExtensionFunction(
            DirectListingsLogic.getAllListings.selector,
            "getAllListings(uint256,uint256)"
        );
        extensionFunctions[11] = IExtension.ExtensionFunction(
            DirectListingsLogic.getAllValidListings.selector,
            "getAllValidListings(uint256,uint256)"
        );
        extensionFunctions[12] = IExtension.ExtensionFunction(
            DirectListingsLogic.getListing.selector,
            "getListing(uint256)"
        );

        for (uint256 i = 0; i < extensionFunctions.length; i++) {
            extensions[4].functions.push(extensionFunctions[i]);
        }

        // [2] Add extension to registry
        vm.startPrank(registryDeployer);
        extensionRegistry.addExtension(extensions[0]);
        extensionRegistry.addExtension(extensions[1]);
        extensionRegistry.addExtension(extensions[2]);
        extensionRegistry.addExtension(extensions[3]);
        extensionRegistry.addExtension(extensions[4]);
        vm.stopPrank();

        // [3] Deploy `MarketplaceV3` implementation
        vm.startPrank(_adminDeployer);
        MarketplaceV3 router = new MarketplaceV3(address(extensionRegistry), extensionNames);
        vm.stopPrank();

        // [4] Deploy proxy pointing to `MarkeptlaceV3` implementation
        vm.prank(_marketplaceDeployer);
        marketplace = address(
            new TWProxy(
                address(router),
                abi.encodeCall(
                    MarketplaceV3.initialize,
                    (_marketplaceDeployer, "", new address[](0), _marketplaceDeployer, 0)
                )
            )
        );

        // [5] Setup roles for seller and assets
        vm.startPrank(_marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(0));
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), address(0));
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));

        vm.stopPrank();

        vm.label(address(router), "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(erc721), "ERC721_Token");
        vm.label(address(erc1155), "ERC1155_Token");
    }

    function _setupERC721BalanceForSeller(address _seller, uint256 _numOfTokens) private {
        erc721.mint(_seller, _numOfTokens);
    }

    function test_state_initial() public {
        uint256 totalListings = DirectListingsLogic(marketplace).totalListings();
        assertEq(totalListings, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_state_approvedCurrencies() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParams) = _setup_updateListing();
        address currencyToApprove = address(erc20); // same currency as main listing
        uint256 pricePerTokenForCurrency = 2 ether;

        // Seller approves currency for listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: approving listing currency with different price.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency
        );

        // change currency
        currencyToApprove = NATIVE_TOKEN;

        vm.prank(seller);
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency
        );

        assertEq(DirectListingsLogic(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), true);
        assertEq(
            DirectListingsLogic(marketplace).currencyPriceForListing(listingId, NATIVE_TOKEN),
            pricePerTokenForCurrency
        );

        // should revert when updating listing with an approved currency but different price
        listingParams.currency = NATIVE_TOKEN;
        vm.prank(seller);
        vm.expectRevert("Marketplace: price different from approved price");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        // change listingParams.pricePerToken to approved price
        listingParams.pricePerToken = pricePerTokenForCurrency;
        vm.prank(seller);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);
    }

    // function test_state_map_replaceExtension() public {
    //     Map map = Map(MarketplaceEntrypoint(payable(marketplace)).functionMap());

    //     // revert when adding an already set selector
    //     vm.prank(adminDeployer);
    //     vm.expectRevert("Extension already set");
    //     map.addExtension(DirectListingsLogic.createListing.selector, address(0x1234));

    //     // replace an already set selector
    //     vm.prank(adminDeployer);
    //     map.replaceExtension(DirectListingsLogic.createListing.selector, address(0x1234));

    //     assertEq(map.getExtension(DirectListingsLogic.createListing.selector), address(0x1234));
    // }

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
        uint256 listingId = DirectListingsLogic(marketplace).createListing(listingParams);

        // Test consequent state of the contract.

        // Seller is still owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total listings incremented
        assertEq(DirectListingsLogic(marketplace).totalListings(), 1);

        // Fetch listing and verify state.
        IDirectListings.Listing memory listing = DirectListingsLogic(marketplace).getListing(listingId);

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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        vm.expectRevert("Marketplace: invalid startTimestamp.");
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        DirectListingsLogic(marketplace).createListing(listingParams);
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
        listingId = DirectListingsLogic(marketplace).createListing(listingParams);
    }

    function test_state_updateListing() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.pricePerToken = 2 ether;

        vm.prank(seller);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);

        // Test consequent state of the contract.

        // Seller is still owner of token.
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        // Total listings not incremented on update.
        assertEq(DirectListingsLogic(marketplace).totalListings(), 1);

        // Fetch listing and verify state.
        IDirectListings.Listing memory listing = DirectListingsLogic(marketplace).getListing(listingId);

        assertEq(listing.listingId, listingId);
        assertEq(listing.listingCreator, seller);
        assertEq(listing.assetContract, listingParamsToUpdate.assetContract);
        assertEq(listing.tokenId, 0);
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

        address notSeller = getActor(1000); // Someone other than the seller calls update.
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_notOwnerOfListedToken() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens but NOT to seller. A new tokenId will be listed.
        address notSeller = getActor(1000);
        _setupERC721BalanceForSeller(notSeller, 1);

        // Approve Marketplace to transfer token.
        vm.prank(notSeller);
        erc721.setApprovalForAll(marketplace, true);

        // Transfer away owned token.
        vm.prank(seller);
        erc721.transferFrom(seller, address(0x1234), 0);

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
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

        vm.prank(seller);
        vm.expectRevert("Marketplace: not owner or approved tokens.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingZeroQuantity() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.quantity = 0; // Listing zero quantity

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing zero quantity.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    function test_revert_updateListing_listingInvalidQuantity() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();

        // Mint MORE ERC721 tokens to seller. A new tokenId will be listed.
        _setupERC721BalanceForSeller(seller, 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        assertIsOwnerERC721(address(erc721), seller, tokenIds);

        listingParamsToUpdate.quantity = 2; // Listing more than `1` of the ERC721 token

        vm.prank(seller);
        vm.expectRevert("Marketplace: listing invalid quantity.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
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
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
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

        vm.warp(currentStartTimestamp + 50);
        vm.prank(seller);
        vm.expectRevert("Marketplace: listing already active.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
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
        vm.expectRevert("Marketplace: endTimestamp not greater than startTimestamp.");
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
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
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);
    }

    /*///////////////////////////////////////////////////////////////
                            Cancel listing
    //////////////////////////////////////////////////////////////*/

    function _setup_cancelListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId, ) = _setup_updateListing();
        listing = DirectListingsLogic(marketplace).getListing(listingId);
    }

    function test_state_cancelListing() public {
        (uint256 listingId, IDirectListings.Listing memory existingListingAtId) = _setup_cancelListing();

        // Verify existing listing at `listingId`
        assertEq(existingListingAtId.assetContract, address(erc721));

        vm.prank(seller);
        DirectListingsLogic(marketplace).cancelListing(listingId);

        // status should be `CANCELLED`
        IDirectListings.Listing memory cancelledListing = DirectListingsLogic(marketplace).getListing(listingId);
        assertTrue(cancelledListing.status == IDirectListings.Status.CANCELLED);
    }

    function test_revert_cancelListing_notListingCreator() public {
        (uint256 listingId, IDirectListings.Listing memory existingListingAtId) = _setup_cancelListing();

        // Verify existing listing at `listingId`
        assertEq(existingListingAtId.assetContract, address(erc721));

        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListingsLogic(marketplace).cancelListing(listingId);
    }

    function test_revert_cancelListing_nonExistentListing() public {
        _setup_cancelListing();

        // Verify no listing exists at `nexListingId`
        uint256 nextListingId = DirectListingsLogic(marketplace).totalListings();

        vm.prank(seller);
        vm.expectRevert("Marketplace: invalid listing.");
        DirectListingsLogic(marketplace).cancelListing(nextListingId);
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

        assertEq(DirectListingsLogic(marketplace).getListing(listingId).reserved, true);

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, toApprove);

        assertEq(DirectListingsLogic(marketplace).isBuyerApprovedForListing(listingId, buyer), true);
    }

    function test_revert_approveBuyerForListing_notListingCreator() public {
        uint256 listingId = _setup_approveBuyerForListing();
        bool toApprove = true;

        assertEq(DirectListingsLogic(marketplace).getListing(listingId).reserved, true);

        // Someone other than the seller approves buyer for reserved listing.
        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, toApprove);
    }

    function test_revert_approveBuyerForListing_listingNotReserved() public {
        (uint256 listingId, IDirectListings.ListingParameters memory listingParamsToUpdate) = _setup_updateListing();
        bool toApprove = true;

        assertEq(DirectListingsLogic(marketplace).getListing(listingId).reserved, true);

        listingParamsToUpdate.reserved = false;

        vm.prank(seller);
        DirectListingsLogic(marketplace).updateListing(listingId, listingParamsToUpdate);

        assertEq(DirectListingsLogic(marketplace).getListing(listingId).reserved, false);

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: listing not reserved.");
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, toApprove);
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

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency
        );

        assertEq(DirectListingsLogic(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), true);
        assertEq(
            DirectListingsLogic(marketplace).currencyPriceForListing(listingId, NATIVE_TOKEN),
            pricePerTokenForCurrency
        );
    }

    function test_revert_approveCurrencyForListing_notListingCreator() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = NATIVE_TOKEN;
        uint256 pricePerTokenForCurrency = 2 ether;

        // Someone other than seller approves buyer for reserved listing.
        address notSeller = getActor(1000);
        vm.prank(notSeller);
        vm.expectRevert("Marketplace: not listing creator.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency
        );
    }

    function test_revert_approveCurrencyForListing_reApprovingMainCurrency() public {
        uint256 listingId = _setup_approveCurrencyForListing();
        address currencyToApprove = DirectListingsLogic(marketplace).getListing(listingId).currency;
        uint256 pricePerTokenForCurrency = 2 ether;

        // Seller approves buyer for reserved listing.
        vm.prank(seller);
        vm.expectRevert("Marketplace: approving listing currency with different price.");
        DirectListingsLogic(marketplace).approveCurrencyForListing(
            listingId,
            currencyToApprove,
            pricePerTokenForCurrency
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Buy from listing
    //////////////////////////////////////////////////////////////*/

    function _setup_buyFromListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId, ) = _setup_updateListing();
        listing = DirectListingsLogic(marketplace).getListing(listingId);
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);

        // Verify that buyer is owner of listed tokens, post-sale.
        assertIsOwnerERC721(address(erc721), buyer, tokenIds);
        assertIsNotOwnerERC721(address(erc721), seller, tokenIds);

        // Verify seller is paid total price.
        assertBalERC20Eq(address(erc20), buyer, 0);
        assertBalERC20Eq(address(erc20), seller, totalPrice);

        if (quantityToBuy == listing.quantity) {
            // Verify listing status is `COMPLETED` if listing tokens are all bought.
            IDirectListings.Listing memory completedListing = DirectListingsLogic(marketplace).getListing(listingId);
            assertTrue(completedListing.status == IDirectListings.Status.COMPLETED);
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
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken);

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing{ value: totalPrice }(
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
            // Verify listing status is `COMPLETED` if listing tokens are all bought.
            IDirectListings.Listing memory completedListing = DirectListingsLogic(marketplace).getListing(listingId);
            assertTrue(completedListing.status == IDirectListings.Status.COMPLETED);
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
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken);

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing{ value: totalPrice - 1 }( // sending insufficient value
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
        DirectListingsLogic(marketplace).approveCurrencyForListing(listingId, currency, pricePerToken);

        // Seller approves buyer for listing
        vm.prank(seller);
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing{ value: totalPrice }(
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        assertEq(DirectListingsLogic(marketplace).isCurrencyApprovedForListing(listingId, NATIVE_TOKEN), false);

        vm.warp(listing.startTimestamp);
        vm.prank(buyer);
        vm.expectRevert("Paying in invalid currency.");
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, NATIVE_TOKEN, totalPrice);
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);
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
        listingId = DirectListingsLogic(marketplace).createListing(listingParams);
    }
}

contract IssueC2_MarketplaceDirectListingsTest is BaseTest {
    address private registryDeployer;

    ExtensionRegistry private extensionRegistry;

    mapping(uint256 => IExtension.Extension) private extensions;

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
        registryDeployer = getActor(4);

        vm.prank(registryDeployer);
        extensionRegistry = new ExtensionRegistry(registryDeployer);

        setupMarketplace(adminDeployer, marketplaceDeployer);
    }

    function setupMarketplace(address _adminDeployer, address _marketplaceDeployer) private {
        string[] memory extensionNames = new string[](5);

        // Deploy extensions

        // Extension: ERC2771Context
        address erc2771Context = address(new MetaTx(forwarders()));

        extensions[0].metadata = IExtension.ExtensionMetadata({
            name: "ERC2771Context",
            metadataURI: "ipfs://ERC2771Context",
            implementation: erc2771Context
        });

        extensions[0].functions.push(
            IExtension.ExtensionFunction(ERC2771Context.isTrustedForwarder.selector, "isTrustedForwarder(address)")
        );
        extensionNames[0] = extensions[0].metadata.name;

        // Extension: PermissionsEnumerable
        address permissions = address(new PermissionsEnumerableImpl());

        extensions[1].metadata = IExtension.ExtensionMetadata({
            name: "PermissionsEnumerable",
            metadataURI: "ipfs://PermissionsEnumerable",
            implementation: permissions
        });

        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.hasRole.selector, "hasRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.hasRoleWithSwitch.selector, "hasRoleWithSwitch(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.getRoleAdmin.selector, "getRoleAdmin(bytes32)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.grantRole.selector, "grantRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.revokeRole.selector, "revokeRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(Permissions.renounceRole.selector, "renounceRole(bytes32,address)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(PermissionsEnumerable.getRoleMember.selector, "getRoleMember(bytes32,uint256)")
        );
        extensions[1].functions.push(
            IExtension.ExtensionFunction(
                PermissionsEnumerable.getRoleMemberCount.selector,
                "getRoleMemberCount(bytes32)"
            )
        );
        extensionNames[1] = extensions[1].metadata.name;

        // Extension: ContractMetadata
        address contractMetadata = address(new ContractMetadataImpl());

        extensions[2].metadata = IExtension.ExtensionMetadata({
            name: "ContractMetadata",
            metadataURI: "ipfs://ContractMetadata",
            implementation: contractMetadata
        });

        extensions[2].functions.push(
            IExtension.ExtensionFunction(ContractMetadata.contractURI.selector, "contractURI()")
        );
        extensions[2].functions.push(
            IExtension.ExtensionFunction(ContractMetadata.setContractURI.selector, "setContractURI(string)")
        );
        extensionNames[2] = extensions[2].metadata.name;

        // Extension: PlatformFee
        address platformFee = address(new PlatformFeeImpl());

        extensions[3].metadata = IExtension.ExtensionMetadata({
            name: "PlatformFee",
            metadataURI: "ipfs://PlatformFee",
            implementation: platformFee
        });

        extensions[3].functions.push(
            IExtension.ExtensionFunction(PlatformFee.getPlatformFeeInfo.selector, "getPlatformFeeInfo()")
        );
        extensions[3].functions.push(
            IExtension.ExtensionFunction(PlatformFee.setPlatformFeeInfo.selector, "setPlatformFeeInfo(address,uint256)")
        );
        extensionNames[3] = extensions[3].metadata.name;

        // [1] Index `DirectListings` functions in `Extension`
        extensions[4].metadata = IExtension.ExtensionMetadata({
            name: "DirectListingsLogic",
            metadataURI: "ipfs://direct",
            implementation: address(new DirectListingsLogic(address(weth)))
        });
        extensionNames[4] = extensions[4].metadata.name;

        IExtension.ExtensionFunction[] memory extensionFunctions = new IExtension.ExtensionFunction[](13);
        extensionFunctions[0] = IExtension.ExtensionFunction(
            DirectListingsLogic.totalListings.selector,
            "totalListings()"
        );
        extensionFunctions[1] = IExtension.ExtensionFunction(
            DirectListingsLogic.isBuyerApprovedForListing.selector,
            "isBuyerApprovedForListing(uint256,address)"
        );
        extensionFunctions[2] = IExtension.ExtensionFunction(
            DirectListingsLogic.isCurrencyApprovedForListing.selector,
            "isCurrencyApprovedForListing(uint256,address)"
        );
        extensionFunctions[3] = IExtension.ExtensionFunction(
            DirectListingsLogic.currencyPriceForListing.selector,
            "currencyPriceForListing(uint256,address)"
        );
        extensionFunctions[4] = IExtension.ExtensionFunction(
            DirectListingsLogic.createListing.selector,
            "createListing((address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extensionFunctions[5] = IExtension.ExtensionFunction(
            DirectListingsLogic.updateListing.selector,
            "updateListing(uint256,(address,uint256,uint256,address,uint256,uint128,uint128,bool))"
        );
        extensionFunctions[6] = IExtension.ExtensionFunction(
            DirectListingsLogic.cancelListing.selector,
            "cancelListing(uint256)"
        );
        extensionFunctions[7] = IExtension.ExtensionFunction(
            DirectListingsLogic.approveBuyerForListing.selector,
            "approveBuyerForListing(uint256,address,bool)"
        );
        extensionFunctions[8] = IExtension.ExtensionFunction(
            DirectListingsLogic.approveCurrencyForListing.selector,
            "approveCurrencyForListing(uint256,address,uint256)"
        );
        extensionFunctions[9] = IExtension.ExtensionFunction(
            DirectListingsLogic.buyFromListing.selector,
            "buyFromListing(uint256,address,uint256,address,uint256)"
        );
        extensionFunctions[10] = IExtension.ExtensionFunction(
            DirectListingsLogic.getAllListings.selector,
            "getAllListings(uint256,uint256)"
        );
        extensionFunctions[11] = IExtension.ExtensionFunction(
            DirectListingsLogic.getAllValidListings.selector,
            "getAllValidListings(uint256,uint256)"
        );
        extensionFunctions[12] = IExtension.ExtensionFunction(
            DirectListingsLogic.getListing.selector,
            "getListing(uint256)"
        );

        for (uint256 i = 0; i < extensionFunctions.length; i++) {
            extensions[4].functions.push(extensionFunctions[i]);
        }

        // [2] Add extension to registry
        vm.startPrank(registryDeployer);
        extensionRegistry.addExtension(extensions[0]);
        extensionRegistry.addExtension(extensions[1]);
        extensionRegistry.addExtension(extensions[2]);
        extensionRegistry.addExtension(extensions[3]);
        extensionRegistry.addExtension(extensions[4]);
        vm.stopPrank();

        // [3] Deploy `MarketplaceV3` implementation
        vm.startPrank(_adminDeployer);
        MarketplaceV3 router = new MarketplaceV3(address(extensionRegistry), extensionNames);
        vm.stopPrank();

        // [4] Deploy proxy pointing to `MarkeptlaceV3` implementation
        vm.prank(_marketplaceDeployer);
        marketplace = address(
            new TWProxy(
                address(router),
                abi.encodeCall(
                    MarketplaceV3.initialize,
                    (_marketplaceDeployer, "", new address[](0), _marketplaceDeployer, 0)
                )
            )
        );

        // [5] Setup roles for seller and assets
        vm.startPrank(_marketplaceDeployer);
        Permissions(marketplace).revokeRole(keccak256("ASSET_ROLE"), address(0));
        Permissions(marketplace).revokeRole(keccak256("LISTER_ROLE"), address(0));
        Permissions(marketplace).grantRole(keccak256("LISTER_ROLE"), seller);
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc721));
        Permissions(marketplace).grantRole(keccak256("ASSET_ROLE"), address(erc1155));

        vm.stopPrank();

        vm.label(address(router), "MarketplaceV3_Impl");
        vm.label(marketplace, "Marketplace");
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
        listingId = DirectListingsLogic(marketplace).createListing(listingParams);
    }

    function _setup_buyFromListing() private returns (uint256 listingId, IDirectListings.Listing memory listing) {
        (listingId, ) = _setup_updateListing();
        listing = DirectListingsLogic(marketplace).getListing(listingId);
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
        DirectListingsLogic(marketplace).approveBuyerForListing(listingId, buyer, true);

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
        DirectListingsLogic(marketplace).updateListing(listingId, listingParams);

        // Buy listing
        // vm.warp(listing.startTimestamp);
        // vm.prank(buyer);
        // DirectListingsLogic(marketplace).buyFromListing(listingId, buyFor, quantityToBuy, currency, totalPrice);

        // // Buyer is owner of the swapped out token (tokenId = 1) and not the expected (tokenId = 0)
        // assertIsOwnerERC721(address(erc721), buyer, swappedTokenIds);
        // assertIsNotOwnerERC721(address(erc721), buyer, expectedTokenIds);

        // // Verify seller is paid total price.
        // assertBalERC20Eq(address(erc20), buyer, 0);
        // assertBalERC20Eq(address(erc20), seller, totalPrice);
    }
}
