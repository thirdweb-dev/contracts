// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Drop, IDrop, IClaimConditionMultiPhase, IClaimCondition } from "contracts/extension/upgradeable/Drop.sol";
import "../../../ExtensionUtilTest.sol";

contract MyDropUpg is Drop {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

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
        return msg.sender == admin;
    }

    /**
     * note: the functions below are dummy functions for test purposes,
     * to directly access and set/reset state without going through the actual functions and checks
     */

    function setCondition(ClaimCondition calldata condition, uint256 _conditionId) public {
        _dropStorage().claimCondition.conditions[_conditionId] = condition;
    }

    function setSupplyClaimedForCondition(uint256 _conditionId, uint256 _supplyClaimed) public {
        _dropStorage().claimCondition.conditions[_conditionId].supplyClaimed = _supplyClaimed;
    }
}

contract UpgradeableDrop_SetClaimConditions is ExtensionUtilTest {
    MyDropUpg internal ext;
    address internal admin;

    IClaimCondition.ClaimCondition[] internal newClaimConditions;
    IClaimCondition.ClaimCondition[] internal oldClaimConditions;

    event ClaimConditionsUpdated(IClaimCondition.ClaimCondition[] claimConditions, bool resetEligibility);

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        ext = new MyDropUpg(admin);

        _setOldConditionsState();

        newClaimConditions.push(
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

        newClaimConditions.push(
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
    }

    function _setOldConditionsState() public {
        oldClaimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 10,
                maxClaimableSupply: 100,
                supplyClaimed: 0,
                quantityLimitPerWallet: 1,
                merkleRoot: bytes32(0),
                pricePerToken: 10,
                currency: address(erc20),
                metadata: ""
            })
        );

        oldClaimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 20,
                maxClaimableSupply: 100,
                supplyClaimed: 0,
                quantityLimitPerWallet: 1,
                merkleRoot: bytes32(0),
                pricePerToken: 10,
                currency: address(erc20),
                metadata: ""
            })
        );

        oldClaimConditions.push(
            IClaimCondition.ClaimCondition({
                startTimestamp: 30,
                maxClaimableSupply: 100,
                supplyClaimed: 0,
                quantityLimitPerWallet: 1,
                merkleRoot: bytes32(0),
                pricePerToken: 10,
                currency: address(erc20),
                metadata: ""
            })
        );

        vm.prank(admin);
        ext.setClaimConditions(oldClaimConditions, false);
        (, uint256 count) = ext.claimCondition();
        assertEq(count, oldClaimConditions.length);

        ext.setSupplyClaimedForCondition(0, 5);
        ext.setSupplyClaimedForCondition(0, 20);
        ext.setSupplyClaimedForCondition(0, 100);
    }

    function test_setClaimConditions_notAuthorized() public {
        vm.expectRevert("Not authorized");
        ext.setClaimConditions(newClaimConditions, false);

        vm.expectRevert("Not authorized");
        ext.setClaimConditions(newClaimConditions, true);
    }

    modifier whenCallerAuthorized() {
        vm.startPrank(admin);
        _;
        vm.stopPrank();
    }

    function test_setClaimConditions_incorrectStartTimestamps() public whenCallerAuthorized {
        // reverse the order of timestamps
        newClaimConditions[0].startTimestamp = newClaimConditions[1].startTimestamp + 100;

        vm.expectRevert(bytes("ST"));
        ext.setClaimConditions(newClaimConditions, false);

        vm.expectRevert(bytes("ST"));
        ext.setClaimConditions(newClaimConditions, true);
    }

    modifier whenCorrectTimestamps() {
        _;
    }

    // ==================
    // ======= Test branch: claim eligibility reset
    // ==================

    function test_setClaimConditions_resetEligibility_startIndex() public whenCallerAuthorized whenCorrectTimestamps {
        (, uint256 oldCount) = ext.claimCondition();

        ext.setClaimConditions(newClaimConditions, true);

        (uint256 newStartIndex, ) = ext.claimCondition();
        assertEq(newStartIndex, oldCount);
    }

    function test_setClaimConditions_resetEligibility_conditionCount()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
    {
        (, uint256 oldCount) = ext.claimCondition();
        assertEq(oldCount, oldClaimConditions.length);

        ext.setClaimConditions(newClaimConditions, true);

        (uint256 newStartIndex, uint256 newCount) = ext.claimCondition();
        assertEq(newCount, newClaimConditions.length);
    }

    function test_setClaimConditions_resetEligibility_conditionState()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
    {
        ext.setClaimConditions(newClaimConditions, true);

        (uint256 newStartIndex, uint256 newCount) = ext.claimCondition();

        for (uint256 i = 0; i < newCount; i++) {
            IClaimCondition.ClaimCondition memory _claimCondition = ext.getClaimConditionById(i + newStartIndex);

            assertEq(_claimCondition.startTimestamp, newClaimConditions[i].startTimestamp);
            assertEq(_claimCondition.maxClaimableSupply, newClaimConditions[i].maxClaimableSupply);
            assertEq(_claimCondition.supplyClaimed, 0);
        }
    }

    function test_setClaimConditions_resetEligibility_oldConditionsDeleted()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
    {
        (uint256 oldStartIndex, uint256 oldCount) = ext.claimCondition();
        assertEq(oldCount, oldClaimConditions.length);

        ext.setClaimConditions(newClaimConditions, true);

        for (uint256 i = 0; i < oldCount; i++) {
            IClaimCondition.ClaimCondition memory _claimCondition = ext.getClaimConditionById(i + oldStartIndex);

            assertEq(_claimCondition.startTimestamp, 0);
            assertEq(_claimCondition.maxClaimableSupply, 0);
            assertEq(_claimCondition.supplyClaimed, 0);
            assertEq(_claimCondition.quantityLimitPerWallet, 0);
            assertEq(_claimCondition.merkleRoot, bytes32(0));
            assertEq(_claimCondition.pricePerToken, 0);
            assertEq(_claimCondition.currency, address(0));
            assertEq(_claimCondition.metadata, "");
        }
    }

    function test_setClaimConditions_resetEligibility_event() public whenCallerAuthorized whenCorrectTimestamps {
        // TODO: fix/review event data check by setting last param true
        vm.expectEmit(false, false, false, false);
        emit ClaimConditionsUpdated(newClaimConditions, true);
        ext.setClaimConditions(newClaimConditions, true);
    }

    // ==================
    // ======= Test branch: claim eligibility not reset
    // ==================

    function test_setClaimConditions_noReset_maxClaimableLessThanClaimed()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
    {
        IClaimCondition.ClaimCondition memory _oldCondition = ext.getClaimConditionById(0);

        // set new maxClaimableSupply less than supplyClaimed of the old condition
        newClaimConditions[0].maxClaimableSupply = _oldCondition.supplyClaimed - 1;

        vm.expectRevert("max supply claimed");
        ext.setClaimConditions(newClaimConditions, false);
    }

    modifier whenMaxClaimableNotLessThanClaimed() {
        _;
    }

    function test_setClaimConditions_noReset_startIndex()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
        whenMaxClaimableNotLessThanClaimed
    {
        (uint256 oldStartIndex, ) = ext.claimCondition();

        ext.setClaimConditions(newClaimConditions, false);

        (uint256 newStartIndex, ) = ext.claimCondition();
        assertEq(newStartIndex, oldStartIndex);
    }

    function test_setClaimConditions_noReset_conditionCount()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
        whenMaxClaimableNotLessThanClaimed
    {
        (, uint256 oldCount) = ext.claimCondition();
        assertEq(oldCount, oldClaimConditions.length);

        ext.setClaimConditions(newClaimConditions, false);

        (uint256 newStartIndex, uint256 newCount) = ext.claimCondition();
        assertEq(newCount, newClaimConditions.length);
    }

    function test_setClaimConditions_noReset_conditionState()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
        whenMaxClaimableNotLessThanClaimed
    {
        (, uint256 oldCount) = ext.claimCondition();

        // setting array size as this way to avoid out-of-bound error in the second loop
        uint256 length = newClaimConditions.length > oldCount ? newClaimConditions.length : oldCount;
        IClaimCondition.ClaimCondition[] memory _oldConditions = new IClaimCondition.ClaimCondition[](length);

        for (uint256 i = 0; i < oldCount; i++) {
            _oldConditions[i] = ext.getClaimConditionById(i);
        }

        ext.setClaimConditions(newClaimConditions, false);

        (uint256 newStartIndex, uint256 newCount) = ext.claimCondition();

        for (uint256 i = 0; i < newCount; i++) {
            IClaimCondition.ClaimCondition memory _claimCondition = ext.getClaimConditionById(i + newStartIndex);

            assertEq(_claimCondition.startTimestamp, newClaimConditions[i].startTimestamp);
            assertEq(_claimCondition.maxClaimableSupply, newClaimConditions[i].maxClaimableSupply);
            assertEq(_claimCondition.supplyClaimed, _oldConditions[i].supplyClaimed);
        }
    }

    function test_setClaimConditions_resetEligibility_oldConditionsDeletedOrReplaced()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
        whenMaxClaimableNotLessThanClaimed
    {
        (uint256 oldStartIndex, uint256 oldCount) = ext.claimCondition();
        assertEq(oldCount, oldClaimConditions.length);

        ext.setClaimConditions(newClaimConditions, false);
        (, uint256 newCount) = ext.claimCondition();

        for (uint256 i = 0; i < oldCount; i++) {
            IClaimCondition.ClaimCondition memory _claimCondition = ext.getClaimConditionById(i + oldStartIndex);

            if (i >= newCount) {
                // case where deleted

                assertEq(_claimCondition.startTimestamp, 0);
                assertEq(_claimCondition.maxClaimableSupply, 0);
                assertEq(_claimCondition.supplyClaimed, 0);
                assertEq(_claimCondition.quantityLimitPerWallet, 0);
                assertEq(_claimCondition.merkleRoot, bytes32(0));
                assertEq(_claimCondition.pricePerToken, 0);
                assertEq(_claimCondition.currency, address(0));
                assertEq(_claimCondition.metadata, "");
            } else {
                // case where replaced

                // supply claimed should be same as old condition, hence not checked below

                assertEq(_claimCondition.startTimestamp, newClaimConditions[i].startTimestamp);
                assertEq(_claimCondition.maxClaimableSupply, newClaimConditions[i].maxClaimableSupply);
                assertEq(_claimCondition.quantityLimitPerWallet, newClaimConditions[i].quantityLimitPerWallet);
                assertEq(_claimCondition.merkleRoot, newClaimConditions[i].merkleRoot);
                assertEq(_claimCondition.pricePerToken, newClaimConditions[i].pricePerToken);
                assertEq(_claimCondition.currency, newClaimConditions[i].currency);
                assertEq(_claimCondition.metadata, newClaimConditions[i].metadata);
            }
        }
    }

    function test_setClaimConditions_noReset_event()
        public
        whenCallerAuthorized
        whenCorrectTimestamps
        whenMaxClaimableNotLessThanClaimed
    {
        // TODO: fix/review event data check by setting last param true
        vm.expectEmit(false, false, false, false);
        emit ClaimConditionsUpdated(newClaimConditions, false);
        ext.setClaimConditions(newClaimConditions, false);
    }
}
