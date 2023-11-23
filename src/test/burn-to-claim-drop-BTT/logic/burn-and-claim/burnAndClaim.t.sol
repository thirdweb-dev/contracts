// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import { BurnToClaimDropERC721 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/BurnToClaimDropERC721.sol";
import { BurnToClaimDrop721Logic, ERC721AUpgradeable, DelayedReveal, LazyMint, Drop, BurnToClaim, PrimarySale, PlatformFee } from "contracts/prebuilts/unaudited/burn-to-claim-drop/extension/BurnToClaimDrop721Logic.sol";
import { PermissionsEnumerableImpl } from "contracts/extension/upgradeable/impl/PermissionsEnumerableImpl.sol";
import { Royalty } from "contracts/extension/upgradeable/Royalty.sol";
import { BatchMintMetadata } from "contracts/extension/upgradeable/BatchMintMetadata.sol";
import { IBurnToClaim } from "contracts/extension/interface/IBurnToClaim.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import { Permissions } from "contracts/extension/Permissions.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

contract BurnToClaimDropERC721Logic_BurnAndClaim is BaseTest, IExtension {
    using Strings for uint256;
    using Strings for address;

    event TokensBurnedAndClaimed(
        address indexed originContract,
        address indexed tokenOwner,
        uint256 indexed burnTokenId,
        uint256 quantity
    );

    BurnToClaimDrop721Logic public drop;
    uint256 internal _tokenId;
    uint256 internal _quantity;
    uint256 internal _msgValue;
    uint256[] internal batchIds;
    address internal caller;
    bytes internal data;
    IBurnToClaim.BurnToClaimInfo internal info;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address dropImpl = address(new BurnToClaimDropERC721(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        drop = BurnToClaimDrop721Logic(
            payable(
                address(
                    new TWProxy(
                        dropImpl,
                        abi.encodeCall(
                            BurnToClaimDropERC721.initialize,
                            (
                                deployer,
                                NAME,
                                SYMBOL,
                                CONTRACT_URI,
                                forwarders(),
                                saleRecipient,
                                royaltyRecipient,
                                royaltyBps,
                                platformFeeBps,
                                platformFeeRecipient
                            )
                        )
                    )
                )
            )
        );

        caller = getActor(5);

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
        erc20.mint(caller, 1_000 ether);
        vm.deal(caller, 1_000 ether);

        erc721.mint(deployer, 100);
        erc721NonBurnable.mint(deployer, 100);

        erc1155NonBurnable.mint(deployer, 0, 100);
        erc1155.mint(deployer, 0, 100);
        erc1155.mint(deployer, 1, 100);

        vm.startPrank(deployer);
        erc721.setApprovalForAll(address(drop), true);
        erc1155.setApprovalForAll(address(drop), true);
        erc20.approve(address(drop), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(caller);
        erc721.setApprovalForAll(address(drop), true);
        erc1155.setApprovalForAll(address(drop), true);
        erc20.approve(address(drop), type(uint256).max);
        vm.stopPrank();

        // startId = 0;
        // mint 5 batches
        // vm.startPrank(deployer);
        // for (uint256 i = 0; i < 5; i++) {
        //     uint256 _amount = (i + 1) * 10;
        //     uint256 batchId = startId + _amount;
        //     batchIds.push(batchId);

        //     string memory baseURI = Strings.toString(batchId);
        //     startId = drop.lazyMint(_amount, baseURI, "");
        // }
        // vm.stopPrank();
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](2);

        // Extension: Permissions
        address permissions = address(new PermissionsEnumerableImpl());

        Extension memory extension_permissions;
        extension_permissions.metadata = ExtensionMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: permissions
        });

        extension_permissions.functions = new ExtensionFunction[](1);
        extension_permissions.functions[0] = ExtensionFunction(
            Permissions.hasRole.selector,
            "hasRole(bytes32,address)"
        );

        extensions[0] = extension_permissions;

        address dropLogic = address(new BurnToClaimDrop721Logic());

        Extension memory extension_drop;
        extension_drop.metadata = ExtensionMetadata({
            name: "BurnToClaimDrop721Logic",
            metadataURI: "ipfs://BurnToClaimDrop721Logic",
            implementation: dropLogic
        });

        extension_drop.functions = new ExtensionFunction[](10);
        extension_drop.functions[0] = ExtensionFunction(BurnToClaimDrop721Logic.tokenURI.selector, "tokenURI(uint256)");
        extension_drop.functions[1] = ExtensionFunction(
            BurnToClaimDrop721Logic.lazyMint.selector,
            "lazyMint(uint256,string,bytes)"
        );
        extension_drop.functions[2] = ExtensionFunction(
            BurnToClaimDrop721Logic.setMaxTotalMinted.selector,
            "setMaxTotalMinted(uint256)"
        );
        extension_drop.functions[3] = ExtensionFunction(
            BurnToClaimDrop721Logic.nextTokenIdToMint.selector,
            "nextTokenIdToMint()"
        );
        extension_drop.functions[4] = ExtensionFunction(
            BurnToClaimDrop721Logic.burnAndClaim.selector,
            "burnAndClaim(uint256,uint256)"
        );
        extension_drop.functions[5] = ExtensionFunction(
            BurnToClaim.getBurnToClaimInfo.selector,
            "getBurnToClaimInfo()"
        );
        extension_drop.functions[6] = ExtensionFunction(
            BurnToClaim.setBurnToClaimInfo.selector,
            "setBurnToClaimInfo((address,uint8,uint256,uint256,address))"
        );
        extension_drop.functions[7] = ExtensionFunction(
            BurnToClaimDrop721Logic.nextTokenIdToClaim.selector,
            "nextTokenIdToClaim()"
        );
        extension_drop.functions[8] = ExtensionFunction(ERC721AUpgradeable.balanceOf.selector, "balanceOf(address)");
        extension_drop.functions[9] = ExtensionFunction(ERC721AUpgradeable.ownerOf.selector, "ownerOf(uint256)");

        extensions[1] = extension_drop;
    }

    function test_burnAndClaim_notEnoughLazyMintedTokens() public {
        vm.expectRevert("!Tokens");
        drop.burnAndClaim(0, 1);
    }

    modifier whenEnoughLazyMintedTokens() {
        vm.prank(deployer);
        drop.lazyMint(1000, "ipfs://", "");
        _;
    }

    function test_burnAndClaim_exceedMaxTotalMint() public whenEnoughLazyMintedTokens {
        vm.prank(deployer);
        drop.setMaxTotalMinted(1); //set max total mint cap as 1

        vm.expectRevert("exceed max total mint cap.");
        drop.burnAndClaim(0, 2);
    }

    modifier whenNotExceedMaxTotalMinted() {
        vm.prank(deployer);
        drop.setMaxTotalMinted(1000);
        _;
    }

    function test_burnAndClaim_burnToClaimInfoNotSet() public whenEnoughLazyMintedTokens whenNotExceedMaxTotalMinted {
        // it will fail when verifyClaim tries to check owner/balance on nft contract which is still address(0)
        vm.expectRevert();
        drop.burnAndClaim(0, 1);
    }

    // ==================
    // ======= Test branch: burn-to-claim origin contract is ERC721
    // ==================

    modifier whenBurnToClaimInfoSetERC721() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc721NonBurnable),
            tokenType: IBurnToClaim.TokenType.ERC721,
            tokenId: 0,
            mintPriceForNewToken: 0,
            currency: address(erc20)
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC721_invalidQuantity()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSetERC721
    {
        vm.expectRevert("Invalid amount");
        drop.burnAndClaim(0, 0);
    }

    modifier whenValidQuantityERC721() {
        _quantity = 1;
        _;
    }

    function test_burnAndClaim_ERC721_notOwner()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSetERC721
        whenValidQuantityERC721
    {
        vm.expectRevert("!Owner");
        drop.burnAndClaim(_tokenId, _quantity);
    }

    modifier whenCorrectOwnerERC721() {
        vm.startPrank(deployer);
        erc721NonBurnable.transferFrom(deployer, caller, _tokenId);
        erc721.transferFrom(deployer, caller, _tokenId);
        vm.stopPrank();
        _;
    }

    function test_burnAndClaim_ERC721_notBurnable()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSetERC721
        whenValidQuantityERC721
        whenCorrectOwnerERC721
    {
        vm.expectRevert(); // `EvmError: Revert` when trying to burn on a non-burnable contract
        vm.prank(caller);
        drop.burnAndClaim(_tokenId, _quantity);
    }

    modifier whenBurnToClaimInfoSet_ERC721Burnable() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc721),
            tokenType: IBurnToClaim.TokenType.ERC721,
            tokenId: 0,
            mintPriceForNewToken: 0,
            currency: address(erc20)
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC721_mintPriceZero_msgValueNonZero()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable
        whenValidQuantityERC721
        whenCorrectOwnerERC721
    {
        vm.expectRevert("!Value");
        vm.prank(caller);
        drop.burnAndClaim{ value: 1 }(_tokenId, _quantity);
    }

    modifier whenMsgValueZero() {
        _msgValue = 0;
        _;
    }

    function test_burnAndClaim_ERC721_mintPriceZero()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable
        whenValidQuantityERC721
        whenCorrectOwnerERC721
        whenMsgValueZero
    {
        // state before
        uint256 _nextTokenIdToClaim = drop.nextTokenIdToClaim();

        // burn and claim
        vm.prank(caller);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);

        // check state after
        vm.expectRevert(); // because token non-existent after burning
        erc721.ownerOf(_tokenId);

        assertEq(drop.balanceOf(caller), _quantity);
        assertEq(drop.ownerOf(_nextTokenIdToClaim), caller);
        assertEq(drop.nextTokenIdToClaim(), _nextTokenIdToClaim + _quantity);
    }

    function test_burnAndClaim_ERC721_mintPriceZero_event()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable
        whenValidQuantityERC721
        whenCorrectOwnerERC721
        whenMsgValueZero
    {
        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensBurnedAndClaimed(address(erc721), caller, _tokenId, _quantity);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);
    }

    modifier whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceNativeToken() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc721),
            tokenType: IBurnToClaim.TokenType.ERC721,
            tokenId: 0,
            mintPriceForNewToken: 100,
            currency: NATIVE_TOKEN
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC721_mintPriceNonZero_nativeToken_incorrectMsgValue()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceNativeToken
        whenValidQuantityERC721
        whenCorrectOwnerERC721
    {
        uint256 incorrectTotalPrice = (info.mintPriceForNewToken * _quantity) + 1;

        vm.prank(caller);
        vm.expectRevert("Invalid msg value");
        drop.burnAndClaim{ value: incorrectTotalPrice }(_tokenId, _quantity);
    }

    modifier whenCorrectMsgValue() {
        _msgValue = info.mintPriceForNewToken * _quantity;
        _;
    }

    function test_burnAndClaim_ERC721_mintPriceNonZero_nativeToken()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceNativeToken
        whenValidQuantityERC721
        whenCorrectOwnerERC721
        whenCorrectMsgValue
    {
        // state before
        uint256 _nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(platformFeeRecipient.balance, 0);
        assertEq(saleRecipient.balance, 0);
        assertEq(caller.balance, 1000 ether);

        // burn and claim
        vm.prank(caller);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);

        // check state after
        uint256 totalPrice = (info.mintPriceForNewToken * _quantity);
        uint256 _platformFee = (totalPrice * platformFeeBps) / 10_000;
        uint256 _saleProceeds = totalPrice - _platformFee;
        vm.expectRevert(); // because token non-existent after burning
        erc721.ownerOf(_tokenId);

        assertEq(drop.balanceOf(caller), _quantity);
        assertEq(drop.ownerOf(_nextTokenIdToClaim), caller);
        assertEq(drop.nextTokenIdToClaim(), _nextTokenIdToClaim + _quantity);
        assertEq(platformFeeRecipient.balance, _platformFee);
        assertEq(saleRecipient.balance, _saleProceeds);
        assertEq(caller.balance, 1000 ether - totalPrice);
    }

    function test_burnAndClaim_ERC721_mintPriceNonZero_nativeToken_event()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceNativeToken
        whenValidQuantityERC721
        whenCorrectOwnerERC721
        whenCorrectMsgValue
    {
        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensBurnedAndClaimed(address(erc721), caller, _tokenId, _quantity);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);
    }

    modifier whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceERC20() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc721),
            tokenType: IBurnToClaim.TokenType.ERC721,
            tokenId: 0,
            mintPriceForNewToken: 100,
            currency: address(erc20)
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC721_mintPriceNonZero_ERC20_nonZeroMsgValue()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceERC20
        whenValidQuantityERC721
        whenCorrectOwnerERC721
    {
        vm.prank(caller);
        vm.expectRevert("Invalid msg value");
        drop.burnAndClaim{ value: 1 }(_tokenId, _quantity);
    }

    function test_burnAndClaim_ERC721_mintPriceNonZero_ERC20()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceERC20
        whenValidQuantityERC721
        whenCorrectOwnerERC721
        whenMsgValueZero
    {
        // state before
        uint256 _nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(erc20.balanceOf(platformFeeRecipient), 0);
        assertEq(erc20.balanceOf(saleRecipient), 0);
        assertEq(erc20.balanceOf(caller), 1000 ether);

        // burn and claim
        vm.prank(caller);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);

        // check state after
        uint256 totalPrice = (info.mintPriceForNewToken * _quantity);
        uint256 _platformFee = (totalPrice * platformFeeBps) / 10_000;
        uint256 _saleProceeds = totalPrice - _platformFee;
        vm.expectRevert(); // because token non-existent after burning
        erc721.ownerOf(_tokenId);

        assertEq(drop.balanceOf(caller), _quantity);
        assertEq(drop.ownerOf(_nextTokenIdToClaim), caller);
        assertEq(drop.nextTokenIdToClaim(), _nextTokenIdToClaim + _quantity);
        assertEq(erc20.balanceOf(platformFeeRecipient), _platformFee);
        assertEq(erc20.balanceOf(saleRecipient), _saleProceeds);
        assertEq(erc20.balanceOf(caller), 1000 ether - totalPrice);
    }

    function test_burnAndClaim_ERC721_mintPriceNonZero_ERC20_event()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC721Burnable_nonZeroPriceERC20
        whenValidQuantityERC721
        whenCorrectOwnerERC721
        whenMsgValueZero
    {
        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensBurnedAndClaimed(address(erc721), caller, _tokenId, _quantity);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);
    }

    // ==================
    // ======= Test branch: burn-to-claim origin contract is ERC1155
    // ==================

    modifier whenBurnToClaimInfoSetERC1155() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc1155NonBurnable),
            tokenType: IBurnToClaim.TokenType.ERC1155,
            tokenId: 0,
            mintPriceForNewToken: 0,
            currency: address(erc20)
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC1155_invalidTokenId()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSetERC1155
    {
        vm.expectRevert("Invalid token Id");
        drop.burnAndClaim(1, 1);
    }

    modifier whenValidTokenIdERC1155() {
        _quantity = 1;
        _tokenId = 0;
        _;
    }

    function test_burnAndClaim_ERC1155_notEnoughBalance()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSetERC1155
        whenValidTokenIdERC1155
    {
        vm.expectRevert("!Balance");
        vm.prank(caller);
        drop.burnAndClaim(_tokenId, _quantity);
    }

    modifier whenEnoughBalanceERC1155() {
        vm.startPrank(deployer);
        erc1155NonBurnable.safeTransferFrom(deployer, caller, _tokenId, 100, "");
        erc1155.safeTransferFrom(deployer, caller, _tokenId, 100, "");
        vm.stopPrank();
        _;
    }

    function test_burnAndClaim_ERC1155_notBurnable()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSetERC1155
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
    {
        vm.expectRevert(); // `EvmError: Revert` when trying to burn on a non-burnable contract
        vm.prank(caller);
        drop.burnAndClaim(_tokenId, _quantity);
    }

    modifier whenBurnToClaimInfoSet_ERC1155Burnable() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc1155),
            tokenType: IBurnToClaim.TokenType.ERC1155,
            tokenId: 0,
            mintPriceForNewToken: 0,
            currency: address(erc20)
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC1155_mintPriceZero_msgValueNonZero()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
    {
        vm.expectRevert("!Value");
        vm.prank(caller);
        drop.burnAndClaim{ value: 1 }(_tokenId, _quantity);
    }

    function test_burnAndClaim_ERC1155_mintPriceZero()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
        whenMsgValueZero
    {
        // state before
        uint256 _nextTokenIdToClaim = drop.nextTokenIdToClaim();

        // burn and claim
        vm.prank(caller);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);

        // check state after
        assertEq(erc1155.balanceOf(caller, _tokenId), 100 - _quantity);
        assertEq(drop.balanceOf(caller), _quantity);
        assertEq(drop.ownerOf(_nextTokenIdToClaim), caller);
        assertEq(drop.nextTokenIdToClaim(), _nextTokenIdToClaim + _quantity);
    }

    function test_burnAndClaim_ERC1155_mintPriceZero_event()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
        whenMsgValueZero
    {
        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensBurnedAndClaimed(address(erc1155), caller, _tokenId, _quantity);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);
    }

    modifier whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceNativeToken() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc1155),
            tokenType: IBurnToClaim.TokenType.ERC1155,
            tokenId: 0,
            mintPriceForNewToken: 100,
            currency: NATIVE_TOKEN
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC1155_mintPriceNonZero_nativeToken_incorrectMsgValue()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceNativeToken
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
    {
        uint256 incorrectTotalPrice = (info.mintPriceForNewToken * _quantity) + 1;

        vm.prank(caller);
        vm.expectRevert("Invalid msg value");
        drop.burnAndClaim{ value: incorrectTotalPrice }(_tokenId, _quantity);
    }

    function test_burnAndClaim_ERC1155_mintPriceNonZero_nativeToken()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceNativeToken
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
        whenCorrectMsgValue
    {
        // state before
        uint256 _nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(platformFeeRecipient.balance, 0);
        assertEq(saleRecipient.balance, 0);
        assertEq(caller.balance, 1000 ether);

        // burn and claim
        vm.prank(caller);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);

        // check state after
        uint256 totalPrice = (info.mintPriceForNewToken * _quantity);
        uint256 _platformFee = (totalPrice * platformFeeBps) / 10_000;
        uint256 _saleProceeds = totalPrice - _platformFee;

        assertEq(erc1155.balanceOf(caller, _tokenId), 100 - _quantity);
        assertEq(drop.balanceOf(caller), _quantity);
        assertEq(drop.ownerOf(_nextTokenIdToClaim), caller);
        assertEq(drop.nextTokenIdToClaim(), _nextTokenIdToClaim + _quantity);
        assertEq(platformFeeRecipient.balance, _platformFee);
        assertEq(saleRecipient.balance, _saleProceeds);
        assertEq(caller.balance, 1000 ether - totalPrice);
    }

    function test_burnAndClaim_ERC1155_mintPriceNonZero_nativeToken_event()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceNativeToken
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
        whenCorrectMsgValue
    {
        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensBurnedAndClaimed(address(erc1155), caller, _tokenId, _quantity);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);
    }

    modifier whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceERC20() {
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(erc1155),
            tokenType: IBurnToClaim.TokenType.ERC1155,
            tokenId: 0,
            mintPriceForNewToken: 100,
            currency: address(erc20)
        });

        vm.prank(deployer);
        drop.setBurnToClaimInfo(info);

        _;
    }

    function test_burnAndClaim_ERC1155_mintPriceNonZero_ERC20_nonZeroMsgValue()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceERC20
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
    {
        vm.prank(caller);
        vm.expectRevert("Invalid msg value");
        drop.burnAndClaim{ value: 1 }(_tokenId, _quantity);
    }

    function test_burnAndClaim_ERC1155_mintPriceNonZero_ERC20()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceERC20
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
        whenMsgValueZero
    {
        // state before
        uint256 _nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(erc20.balanceOf(platformFeeRecipient), 0);
        assertEq(erc20.balanceOf(saleRecipient), 0);
        assertEq(erc20.balanceOf(caller), 1000 ether);

        // burn and claim
        vm.prank(caller);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);

        // check state after
        uint256 totalPrice = (info.mintPriceForNewToken * _quantity);
        uint256 _platformFee = (totalPrice * platformFeeBps) / 10_000;
        uint256 _saleProceeds = totalPrice - _platformFee;

        assertEq(erc1155.balanceOf(caller, _tokenId), 100 - _quantity);
        assertEq(drop.balanceOf(caller), _quantity);
        assertEq(drop.ownerOf(_nextTokenIdToClaim), caller);
        assertEq(drop.nextTokenIdToClaim(), _nextTokenIdToClaim + _quantity);
        assertEq(erc20.balanceOf(platformFeeRecipient), _platformFee);
        assertEq(erc20.balanceOf(saleRecipient), _saleProceeds);
        assertEq(erc20.balanceOf(caller), 1000 ether - totalPrice);
    }

    function test_burnAndClaim_ERC1155_mintPriceNonZero_ERC20_event()
        public
        whenEnoughLazyMintedTokens
        whenNotExceedMaxTotalMinted
        whenBurnToClaimInfoSet_ERC1155Burnable_nonZeroPriceERC20
        whenValidTokenIdERC1155
        whenEnoughBalanceERC1155
        whenMsgValueZero
    {
        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensBurnedAndClaimed(address(erc1155), caller, _tokenId, _quantity);
        drop.burnAndClaim{ value: _msgValue }(_tokenId, _quantity);
    }
}
