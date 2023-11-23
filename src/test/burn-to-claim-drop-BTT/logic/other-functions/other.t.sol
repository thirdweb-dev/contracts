// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import { BurnToClaimDropERC721 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/BurnToClaimDropERC721.sol";
import { BurnToClaimDrop721Logic, IERC2981 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/extension/BurnToClaimDrop721Logic.sol";
import { IDrop } from "contracts/extension/interface/IDrop.sol";
import { IStaking721 } from "contracts/extension/interface/IStaking721.sol";
import { PermissionsEnumerableImpl } from "contracts/extension/upgradeable/impl/PermissionsEnumerableImpl.sol";

import { ERC721AStorage } from "contracts/extension/upgradeable/init/ERC721AInit.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { Permissions } from "contracts/extension/Permissions.sol";

contract MyBurnToClaimDrop721Logic is BurnToClaimDrop721Logic {
    function canSetPlatformFeeInfo() external view returns (bool) {
        return _canSetPlatformFeeInfo();
    }

    function canSetPrimarySaleRecipient() external view returns (bool) {
        return _canSetPrimarySaleRecipient();
    }

    function canSetOwner() external view returns (bool) {
        return _canSetOwner();
    }

    function canSetRoyaltyInfo() external view returns (bool) {
        return _canSetRoyaltyInfo();
    }

    function canSetContractURI() external view returns (bool) {
        return _canSetContractURI();
    }

    function canSetClaimConditions() external view returns (bool) {
        return _canSetClaimConditions();
    }

    function canLazyMint() external view returns (bool) {
        return _canLazyMint();
    }

    function canSetBurnToClaim() external view returns (bool) {
        return _canSetBurnToClaim();
    }

    function beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) external {
        _beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed) external returns (uint256 startTokenId) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        startTokenId = data._currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    function beforeClaim(uint256 _quantity, AllowlistProof calldata proof) external {
        _beforeClaim(address(0), _quantity, address(0), 0, proof, "");
    }

    function mintTo(address _recipient) external {
        _safeMint(_recipient, 1);
    }
}

contract BurnToClaimDrop721Logic_OtherFunctions is BaseTest, IExtension {
    MyBurnToClaimDrop721Logic public drop;
    address internal caller;
    address internal recipient;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address dropImpl = address(new BurnToClaimDropERC721(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        drop = MyBurnToClaimDrop721Logic(
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
        recipient = getActor(6);
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

        extension_permissions.functions = new ExtensionFunction[](3);
        extension_permissions.functions[0] = ExtensionFunction(
            Permissions.hasRole.selector,
            "hasRole(bytes32,address)"
        );
        extension_permissions.functions[1] = ExtensionFunction(
            Permissions.grantRole.selector,
            "grantRole(bytes32,address)"
        );
        extension_permissions.functions[2] = ExtensionFunction(
            Permissions.revokeRole.selector,
            "revokeRole(bytes32,address)"
        );

        extensions[0] = extension_permissions;

        address dropLogic = address(new MyBurnToClaimDrop721Logic());

        Extension memory extension_drop;
        extension_drop.metadata = ExtensionMetadata({
            name: "MyBurnToClaimDrop721Logic",
            metadataURI: "ipfs://MyBurnToClaimDrop721Logic",
            implementation: dropLogic
        });

        extension_drop.functions = new ExtensionFunction[](18);
        extension_drop.functions[0] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetPlatformFeeInfo.selector,
            "canSetPlatformFeeInfo()"
        );
        extension_drop.functions[1] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetPrimarySaleRecipient.selector,
            "canSetPrimarySaleRecipient()"
        );
        extension_drop.functions[2] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetOwner.selector,
            "canSetOwner()"
        );
        extension_drop.functions[3] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetRoyaltyInfo.selector,
            "canSetRoyaltyInfo()"
        );
        extension_drop.functions[4] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetClaimConditions.selector,
            "canSetClaimConditions()"
        );
        extension_drop.functions[5] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetContractURI.selector,
            "canSetContractURI()"
        );
        extension_drop.functions[6] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canLazyMint.selector,
            "canLazyMint()"
        );
        extension_drop.functions[7] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.canSetBurnToClaim.selector,
            "canSetBurnToClaim()"
        );
        extension_drop.functions[8] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.beforeTokenTransfers.selector,
            "beforeTokenTransfers(address,address,uint256,uint256)"
        );
        extension_drop.functions[9] = ExtensionFunction(BurnToClaimDrop721Logic.totalMinted.selector, "totalMinted()");
        extension_drop.functions[10] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.transferTokensOnClaim.selector,
            "transferTokensOnClaim(address,uint256)"
        );
        extension_drop.functions[11] = ExtensionFunction(
            BurnToClaimDrop721Logic.supportsInterface.selector,
            "supportsInterface(bytes4)"
        );
        extension_drop.functions[12] = ExtensionFunction(
            MyBurnToClaimDrop721Logic.beforeClaim.selector,
            "beforeClaim(uint256,(bytes32[],uint256,uint256,address))"
        );
        extension_drop.functions[13] = ExtensionFunction(
            BurnToClaimDrop721Logic.lazyMint.selector,
            "lazyMint(uint256,string,bytes)"
        );
        extension_drop.functions[14] = ExtensionFunction(
            BurnToClaimDrop721Logic.setMaxTotalMinted.selector,
            "setMaxTotalMinted(uint256)"
        );
        extension_drop.functions[15] = ExtensionFunction(BurnToClaimDrop721Logic.burn.selector, "burn(uint256)");
        extension_drop.functions[16] = ExtensionFunction(MyBurnToClaimDrop721Logic.mintTo.selector, "mintTo(address)");
        extension_drop.functions[17] = ExtensionFunction(
            IERC721.setApprovalForAll.selector,
            "setApprovalForAll(address,bool)"
        );

        extensions[1] = extension_drop;
    }

    modifier whenCallerAuthorized() {
        caller = deployer;
        _;
    }

    function test_canSetPlatformFeeInfo_notAuthorized() public {
        vm.prank(caller);
        drop.canSetPlatformFeeInfo();
    }

    function test_canSetPlatformFeeInfo() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetPlatformFeeInfo());
    }

    function test_canSetPrimarySaleRecipient_notAuthorized() public {
        vm.prank(caller);
        drop.canSetPrimarySaleRecipient();
    }

    function test_canSetPrimarySaleRecipient() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetPrimarySaleRecipient());
    }

    function test_canSetOwner_notAuthorized() public {
        vm.prank(caller);
        drop.canSetOwner();
    }

    function test_canSetOwner() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetOwner());
    }

    function test_canSetRoyaltyInfo_notAuthorized() public {
        vm.prank(caller);
        drop.canSetRoyaltyInfo();
    }

    function test_canSetRoyaltyInfo() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetRoyaltyInfo());
    }

    function test_canSetContractURI_notAuthorized() public {
        vm.prank(caller);
        drop.canSetContractURI();
    }

    function test_canSetContractURI() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetContractURI());
    }

    function test_canSetClaimConditions_notAuthorized() public {
        vm.prank(caller);
        drop.canSetClaimConditions();
    }

    function test_canSetClaimConditions() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetClaimConditions());
    }

    function test_canLazyMint_notAuthorized() public {
        vm.prank(caller);
        drop.canLazyMint();
    }

    function test_canLazyMint() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canLazyMint());
    }

    function test_canSetBurnToClaim_notAuthorized() public {
        vm.prank(caller);
        drop.canSetBurnToClaim();
    }

    function test_canSetBurnToClaim() public whenCallerAuthorized {
        vm.prank(caller);
        assertTrue(drop.canSetBurnToClaim());
    }

    function test_beforeTokenTransfers_restricted_notTransferRole() public {
        vm.prank(deployer);
        Permissions(address(drop)).revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.expectRevert("!Transfer-Role");
        drop.beforeTokenTransfers(caller, address(0x123), 0, 1);
    }

    modifier whenTransferRole() {
        vm.prank(deployer);
        Permissions(address(drop)).grantRole(keccak256("TRANSFER_ROLE"), caller);
        _;
    }

    function test_beforeTokenTransfers_restricted() public whenTransferRole {
        drop.beforeTokenTransfers(caller, address(0x123), 0, 1);
    }

    function test_totalMinted() public {
        uint256 totalMinted = drop.totalMinted();
        assertEq(totalMinted, 0);

        // mint tokens
        drop.transferTokensOnClaim(caller, 10);
        totalMinted = drop.totalMinted();
        assertEq(totalMinted, 10);
    }

    function test_supportsInterface() public {
        assertTrue(drop.supportsInterface(type(IERC2981).interfaceId));
        assertFalse(drop.supportsInterface(type(IStaking721).interfaceId));
    }

    function test_beforeClaim() public {
        bytes32[] memory emptyBytes32Array = new bytes32[](0);
        IDrop.AllowlistProof memory proof = IDrop.AllowlistProof(emptyBytes32Array, 0, 0, address(0));
        drop.beforeClaim(0, proof);

        vm.expectRevert("!Tokens");
        drop.beforeClaim(1, proof);

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", "");

        vm.prank(deployer);
        drop.setMaxTotalMinted(1);

        vm.expectRevert("exceed max total mint cap.");
        drop.beforeClaim(10, proof);

        vm.prank(deployer);
        drop.setMaxTotalMinted(0);

        drop.beforeClaim(10, proof); // no revert if max total mint cap is set to 0
    }

    //=========== burn tests =========

    function test_burn_whenNotOwnerNorApproved() public {
        // mint
        drop.mintTo(recipient);

        // burn
        vm.expectRevert();
        drop.burn(0);
    }

    function test_burn_whenOwner() public {
        // mint
        drop.mintTo(recipient);

        // burn
        vm.prank(recipient);
        drop.burn(0);

        vm.expectRevert(); // checking non-existent token, because burned
        drop.ownerOf(0);
    }

    function test_burn_whenApproved() public {
        drop.mintTo(recipient);

        vm.prank(recipient);
        drop.setApprovalForAll(caller, true);

        // burn
        vm.prank(caller);
        drop.burn(0);

        vm.expectRevert(); // checking non-existent token, because burned
        drop.ownerOf(0);
    }
}
