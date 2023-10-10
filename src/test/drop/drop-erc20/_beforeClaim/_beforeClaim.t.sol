// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract HarnessDropERC20BeforeClaim is DropERC20 {
    bytes private emptyBytes = bytes("");

    function harness_beforeClaim(uint256 quantity, AllowlistProof calldata _proof) public view {
        _beforeClaim(address(0), quantity, address(0), 0, _proof, emptyBytes);
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

contract DropERC20Test_beforeClaim is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC20BeforeClaim public drop;

    uint256 private mintQty;

    function setUp() public override {
        super.setUp();

        drop = new HarnessDropERC20BeforeClaim();
        drop.initializeHarness(deployer, CONTRACT_URI, saleRecipient, platformFeeBps, platformFeeRecipient);
    }

    modifier setMaxTotalSupply() {
        vm.prank(deployer);
        drop.setMaxTotalSupply(100);
        _;
    }

    modifier qtyExceedMaxTotalSupply() {
        mintQty = 101;
        _;
    }

    function test_revert_MaxSupplyExceeded() public setMaxTotalSupply qtyExceedMaxTotalSupply {
        DropERC20.AllowlistProof memory proof;
        vm.expectRevert("exceed max total supply.");
        drop.harness_beforeClaim(mintQty, proof);
    }
}
