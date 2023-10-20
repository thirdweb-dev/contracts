// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC1155 is DropERC1155 {
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
}

contract DropERC1155Test_canSetFunctions is BaseTest {
    address public dropImp;
    HarnessDropERC1155 public proxy;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC1155.initialize,
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
        );

        dropImp = address(new HarnessDropERC1155());
        proxy = HarnessDropERC1155(address(new TWProxy(dropImp, initializeData)));
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
        assertTrue(proxy.canSetPlatformFeeInfo());
    }

    function test_canSetPlatformFeeInfo_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(proxy.canSetPlatformFeeInfo());
    }

    function test_canSetPrimarySaleRecipient_true() public HasDefaultAdminRole {
        assertTrue(proxy.canSetPrimarySaleRecipient());
    }

    function test_canSetPrimarySaleRecipient_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(proxy.canSetPrimarySaleRecipient());
    }

    function test_canSetOwner_true() public HasDefaultAdminRole {
        assertTrue(proxy.canSetOwner());
    }

    function test_canSetOwner_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(proxy.canSetOwner());
    }

    function test_canSetRoyaltyInfo_true() public HasDefaultAdminRole {
        assertTrue(proxy.canSetRoyaltyInfo());
    }

    function test_canSetRoyaltyInfo_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(proxy.canSetRoyaltyInfo());
    }

    function test_canSetContractURI_true() public HasDefaultAdminRole {
        assertTrue(proxy.canSetContractURI());
    }

    function test_canSetContractURI_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(proxy.canSetContractURI());
    }

    function test_canSetClaimConditions_true() public HasDefaultAdminRole {
        assertTrue(proxy.canSetClaimConditions());
    }

    function test_canSetClaimConditions_false() public DoesNotHaveDefaultAdminRole {
        assertFalse(proxy.canSetClaimConditions());
    }

    function test_canLazyMint_true() public HasMinterRole {
        assertTrue(proxy.canLazyMint());
    }

    function test_canLazyMint_false() public DoesNotHaveMinterRole {
        assertFalse(proxy.canLazyMint());
    }
}
