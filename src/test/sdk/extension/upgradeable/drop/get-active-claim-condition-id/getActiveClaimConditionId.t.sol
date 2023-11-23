// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Drop, IDrop, IClaimConditionMultiPhase, IClaimCondition } from "contracts/extension/upgradeable/Drop.sol";
import "../../../ExtensionUtilTest.sol";

contract MyDropUpg is Drop {
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {}

    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal override returns (uint256 startTokenId) {}

    function _canSetClaimConditions() internal view override returns (bool) {
        return true;
    }
}

contract UpgradeableDrop_GetActiveClaimConditionId is ExtensionUtilTest {
    MyDropUpg internal ext;

    IClaimCondition.ClaimCondition[] internal claimConditions;

    function setUp() public override {
        super.setUp();

        ext = new MyDropUpg();
    }

    function _setConditionsState() public {
        claimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 100,
                maxClaimableSupply: 100,
                supplyClaimed: 0,
                quantityLimitPerWallet: 1,
                merkleRoot: bytes32(0),
                pricePerToken: 10,
                currency: address(erc20),
                metadata: ""
            })
        );

        claimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 200,
                maxClaimableSupply: 100,
                supplyClaimed: 0,
                quantityLimitPerWallet: 1,
                merkleRoot: bytes32(0),
                pricePerToken: 10,
                currency: address(erc20),
                metadata: ""
            })
        );

        claimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 300,
                maxClaimableSupply: 100,
                supplyClaimed: 0,
                quantityLimitPerWallet: 1,
                merkleRoot: bytes32(0),
                pricePerToken: 10,
                currency: address(erc20),
                metadata: ""
            })
        );

        ext.setClaimConditions(claimConditions, false);
    }

    function test_getActiveClaimConditionId_noConditionsSet() public {
        vm.expectRevert("!CONDITION.");
        ext.getActiveClaimConditionId();
    }

    modifier whenConditionsAreSet() {
        _setConditionsState();
        _;
    }

    function test_getActiveClaimConditionId_noActiveCondition() public whenConditionsAreSet {
        vm.expectRevert("!CONDITION.");
        ext.getActiveClaimConditionId();
    }

    modifier whenActiveConditions() {
        _;
    }

    function test_getActiveClaimConditionId_activeConditions() public whenConditionsAreSet whenActiveConditions {
        vm.warp(claimConditions[0].startTimestamp);

        uint256 id = ext.getActiveClaimConditionId();
        assertEq(id, 0);

        vm.warp(claimConditions[1].startTimestamp);

        id = ext.getActiveClaimConditionId();
        assertEq(id, 1);

        vm.warp(claimConditions[2].startTimestamp);

        id = ext.getActiveClaimConditionId();
        assertEq(id, 2);
    }
}
