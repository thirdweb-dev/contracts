// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "lib/forge-std/src/StdCheats.sol";

contract HarnessDropERC20CanSet is DropERC20 {
    function canSetPlatformFeeInfo() external view returns (bool) {
        return _canSetPlatformFeeInfo();
    }

    function canSetPrimarySaleRecipient() external view returns (bool) {
        return _canSetPrimarySaleRecipient();
    }

    function canSetContractURI() external view returns (bool) {
        return _canSetContractURI();
    }

    function canSetClaimConditions() external view returns (bool) {
        return _canSetClaimConditions();
    }

    function initializeHarness(
        address _defaultAdmin,
        string memory _contractURI,
        address _saleRecipient,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");

        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }
}

contract DropERC20Test_canSet is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC20CanSet public drop;

    address private currency;
    address private primarySaleRecipient;
    uint256 private msgValue;
    uint256 private pricePerToken;

    function setUp() public override {
        super.setUp();

        drop = new HarnessDropERC20CanSet();
        drop.initializeHarness(deployer, CONTRACT_URI, saleRecipient, platformFeeBps, platformFeeRecipient);
    }

    modifier callerHasDefaultAdminRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier callerDoesNotHaveDefaultAdminRole() {
        _;
    }

    function test_canSetPlatformFee_returnTrue() public callerHasDefaultAdminRole {
        bool status = drop.canSetPlatformFeeInfo();
        assertEq(status, true);
    }

    function test_canSetPlatformFee_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = drop.canSetPlatformFeeInfo();
        assertEq(status, false);
    }

    function test_canSetPrimarySaleRecipient_returnTrue() public callerHasDefaultAdminRole {
        bool status = drop.canSetPrimarySaleRecipient();
        assertEq(status, true);
    }

    function test_canSetPrimarySaleRecipient_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = drop.canSetPrimarySaleRecipient();
        assertEq(status, false);
    }

    function test_canSetContractURI_returnTrue() public callerHasDefaultAdminRole {
        bool status = drop.canSetContractURI();
        assertEq(status, true);
    }

    function test_canSetContractURI_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = drop.canSetContractURI();
        assertEq(status, false);
    }

    function test_canSetClaimConditions_returnTrue() public callerHasDefaultAdminRole {
        bool status = drop.canSetClaimConditions();
        assertEq(status, true);
    }

    function test_canSetClaimConditions_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = drop.canSetClaimConditions();
        assertEq(status, false);
    }
}
