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

    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof
    ) public view override returns (bool isOverride) {}
}

contract UpgradeableDrop_Claim is ExtensionUtilTest {
    MyDropUpg internal ext;

    address internal _claimer;
    uint256 internal _quantity;
    address internal _currency;
    uint256 internal _pricePerToken;
    IDrop.AllowlistProof internal _allowlistProof;

    IClaimCondition.ClaimCondition[] internal claimConditions;

    function setUp() public override {
        super.setUp();

        ext = new MyDropUpg();
        _claimer = getActor(1);
        _quantity = 10;
    }

    function _setConditionsState() public {
        // values here are not important (except timestamp), since we won't be verifying claim params

        claimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 0,
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

    function test_claim_noConditionsSet() public {
        vm.expectRevert("!CONDITION.");
        ext.claim(_claimer, _quantity, _currency, _pricePerToken, _allowlistProof, "");
    }

    modifier whenConditionsAreSet() {
        _setConditionsState();
        _;
    }

    function test_claim() public whenConditionsAreSet {
        // claim
        vm.prank(_claimer);
        ext.claim(_claimer, _quantity, _currency, _pricePerToken, _allowlistProof, "");

        uint256 supplyClaimedByWallet_1 = ext.getSupplyClaimedByWallet(0, _claimer);
        uint256 supplyClaimed_1 = (ext.getClaimConditionById(0)).supplyClaimed;

        // claim again
        vm.prank(_claimer);
        ext.claim(_claimer, _quantity, _currency, _pricePerToken, _allowlistProof, "");

        uint256 supplyClaimedByWallet_2 = ext.getSupplyClaimedByWallet(0, _claimer);
        uint256 supplyClaimed_2 = (ext.getClaimConditionById(0)).supplyClaimed;

        // check state
        assertEq(supplyClaimedByWallet_1, _quantity);
        assertEq(supplyClaimedByWallet_2, supplyClaimedByWallet_1 + _quantity);

        assertEq(supplyClaimed_1, _quantity);
        assertEq(supplyClaimed_2, supplyClaimed_1 + _quantity);
    }
}
