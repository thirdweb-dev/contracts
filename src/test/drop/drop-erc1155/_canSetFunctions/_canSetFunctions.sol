// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HarnessDropERC1155 is DropERC1155 {
    bytes32 private transferRole;
    bytes32 private minterRole;
    bytes32 private metadataRole;

    function canSetPlatformFeeInfo() external view returns (bool) {
        return _canSetPlatformFeeInfo();
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function canSetPrimarySaleRecipient() external view returns (bool) {
        return _canSetPrimarySaleRecipient();
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function canSetOwner() external view returns (bool) {
        return _canSetOwner();
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function canSetRoyaltyInfo() external view returns (bool) {
        return _canSetRoyaltyInfo();
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function canSetContractURI() external view returns (bool) {
        return _canSetContractURI();
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function canSetClaimConditions() external view returns (bool) {
        return _canSetClaimConditions();
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function canLazyMint() external view virtual returns (bool) {
        return _canLazyMint();
    }

    function initializeHarness(
        address _defaultAdmin,
        string memory _contractURI,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _metadataRole = keccak256("METADATA_ROLE");

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_metadataRole, _defaultAdmin);
        _setRoleAdmin(_metadataRole, _metadataRole);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        transferRole = _transferRole;
        minterRole = _minterRole;
        metadataRole = _metadataRole;
    }
}

contract DropERC1155Test_canSetFunctions is BaseTest {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    HarnessDropERC1155 public drop;

    function setUp() public override {
        super.setUp();
        drop = new HarnessDropERC1155();
        drop.initializeHarness(
            deployer,
            "https://token-cdn-domain/{id}.json",
            deployer,
            deployer,
            1000,
            1000,
            deployer
        );
    }

    modifier HasDefaultAdminRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier DoesNotHaveDefaultAdminRole() {
        vm.startPrank(address(0x123));
        _;
    }

    modifier HasMinterRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier DoesNotHaveMinterRole() {
        vm.startPrank(address(0x123));
        _;
    }

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_canSetPlatformFeeInfo_true() public HasDefaultAdminRole {
        assertTrue(drop.canSetPlatformFeeInfo());
    }

    function test_canSetPlatformFeeInfo_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(drop.canSetPlatformFeeInfo());
    }

    function test_canSetPrimarySaleRecipient_true() public HasDefaultAdminRole {
        assertTrue(drop.canSetPrimarySaleRecipient());
    }

    function test_canSetPrimarySaleRecipient_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(drop.canSetPrimarySaleRecipient());
    }

    function test_canSetOwner_true() public HasDefaultAdminRole {
        assertTrue(drop.canSetOwner());
    }

    function test_canSetOwner_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(drop.canSetOwner());
    }

    function test_canSetRoyaltyInfo_true() public HasDefaultAdminRole {
        assertTrue(drop.canSetRoyaltyInfo());
    }

    function test_canSetRoyaltyInfo_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(drop.canSetRoyaltyInfo());
    }

    function test_canSetContractURI_true() public HasDefaultAdminRole {
        assertTrue(drop.canSetContractURI());
    }

    function test_canSetContractURI_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(drop.canSetContractURI());
    }

    function test_canSetClaimConditions_true() public HasDefaultAdminRole {
        assertTrue(drop.canSetClaimConditions());
    }

    function test_canSetClaimConditions_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(drop.canSetClaimConditions());
    }

    function test_canLazyMint_true() public HasMinterRole {
        assertTrue(drop.canLazyMint());
    }

    function test_canLazyMint_false() public DoesNotHaveMinterRole {
        assertFalse(drop.canLazyMint());
    }
}
