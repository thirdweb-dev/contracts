// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { StakingExtension } from "contracts/extension/StakingExtension.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../mocks/MockERC721.sol";

contract MyStakingContract is ERC20, StakingExtension {
    bool condition;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC721 _nftCollection,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) ERC20(_name, _symbol) StakingExtension(_nftCollection) {
        condition = true;
        _setTimeUnit(_timeUnit);
        _setRewardsPerUnitTime(_rewardsPerUnitTime);
    }

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetStakeConditions() internal view override returns (bool) {
        return condition;
    }

    function _mintRewards(address _staker, uint256 _rewards) internal override {
        _mint(_staker, _rewards);
    }
}

contract StakingExtensionTest is DSTest, Test {
    MyStakingContract internal ext;
    MockERC721 public erc721;

    uint256 timeUnit;
    uint256 rewardsPerUnitTime;

    address deployer;
    address stakerOne;
    address stakerTwo;

    function setUp() public {
        erc721 = new MockERC721();
        timeUnit = 1 hours;
        rewardsPerUnitTime = 100;

        deployer = address(0x123);
        stakerOne = address(0x345);
        stakerTwo = address(0x567);

        erc721.mint(stakerOne, 5); // mint token id 0 to 4
        erc721.mint(stakerTwo, 5); // mint token id 5 to 9

        vm.prank(deployer);
        ext = new MyStakingContract("Test Staking Contract", "TSC", erc721, timeUnit, rewardsPerUnitTime);

        // set approvals
        vm.prank(stakerOne);
        erc721.setApprovalForAll(address(ext), true);

        vm.prank(stakerTwo);
        erc721.setApprovalForAll(address(ext), true);
    }

    /*///////////////////////////////////////////////////////////////
                            Unit tests: Stake
    //////////////////////////////////////////////////////////////*/

    function test_state_stake() public {
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        ext.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate_one = block.timestamp;

        // check balances/ownership of staked tokens
        for (uint256 i = 0; i < _tokenIdsOne.length; i++) {
            assertEq(erc721.ownerOf(_tokenIdsOne[i]), address(ext));
            assertEq(ext.stakerAddress(_tokenIdsOne[i]), stakerOne);
        }
        assertEq(erc721.balanceOf(stakerOne), 2);
        assertEq(erc721.balanceOf(address(ext)), _tokenIdsOne.length);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(_amountStaked, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(100);
        vm.warp(1000);

        // check available rewards after warp
        (, _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );

        //================ second staker ======================
        vm.roll(200);
        vm.warp(2000);
        uint256[] memory _tokenIdsTwo = new uint256[](2);
        _tokenIdsTwo[0] = 5;
        _tokenIdsTwo[1] = 6;

        // stake 2 tokens
        vm.prank(stakerTwo);
        ext.stake(_tokenIdsTwo);
        uint256 timeOfLastUpdate_two = block.timestamp;

        // check balances/ownership of staked tokens
        for (uint256 i = 0; i < _tokenIdsTwo.length; i++) {
            assertEq(erc721.ownerOf(_tokenIdsTwo[i]), address(ext));
            assertEq(ext.stakerAddress(_tokenIdsTwo[i]), stakerTwo);
        }
        assertEq(erc721.balanceOf(stakerTwo), 3);
        assertEq(erc721.balanceOf(address(ext)), _tokenIdsTwo.length + _tokenIdsOne.length);

        // check available rewards right after staking
        (_amountStaked, _availableRewards) = ext.getStakeInfo(stakerTwo);

        assertEq(_amountStaked, _tokenIdsTwo.length);
        assertEq(_availableRewards, 0);

        //=================== warp timestamp to calculate rewards
        vm.roll(300);
        vm.warp(3000);

        // check available rewards for stakerOne
        (, _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );

        // check available rewards for stakerTwo
        (, _availableRewards) = ext.getStakeInfo(stakerTwo);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate_two) * _tokenIdsTwo.length) * rewardsPerUnitTime) / timeUnit)
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Unit tests: claimRewards
    //////////////////////////////////////////////////////////////*/

    function test_state_claimRewards() public {
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        ext.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate_one = block.timestamp;

        //=================== warp timestamp to claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        ext.claimRewards();

        // check reward balances
        assertEq(
            ext.balanceOf(stakerOne),
            ((((block.timestamp - timeOfLastUpdate_one) * _tokenIdsOne.length) * rewardsPerUnitTime) / timeUnit)
        );

        // check available rewards after claiming
        (uint256 _amountStaked, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(_amountStaked, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Unit tests: withdraw
    //////////////////////////////////////////////////////////////*/

    function test_state_withdraw() public {
        //================ first staker ======================
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        ext.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate = block.timestamp;

        // check balances/ownership of staked tokens
        for (uint256 i = 0; i < _tokenIdsOne.length; i++) {
            assertEq(erc721.ownerOf(_tokenIdsOne[i]), address(ext));
            assertEq(ext.stakerAddress(_tokenIdsOne[i]), stakerOne);
        }
        assertEq(erc721.balanceOf(stakerOne), 2);
        assertEq(erc721.balanceOf(address(ext)), _tokenIdsOne.length);

        // check available rewards right after staking
        (uint256 _amountStaked, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(_amountStaked, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);

        //========== warp timestamp before withdraw
        vm.roll(100);
        vm.warp(1000);

        uint256[] memory _tokensToWithdraw = new uint256[](2);
        _tokensToWithdraw[0] = 2;
        _tokensToWithdraw[1] = 0;

        vm.prank(stakerOne);
        ext.withdraw(_tokensToWithdraw);

        // check balances/ownership after withdraw
        for (uint256 i = 0; i < _tokensToWithdraw.length; i++) {
            assertEq(erc721.ownerOf(_tokensToWithdraw[i]), stakerOne);
            assertEq(ext.stakerAddress(_tokensToWithdraw[i]), address(0));
        }
        assertEq(erc721.balanceOf(stakerOne), 4);
        assertEq(erc721.balanceOf(address(ext)), 1);

        // check available rewards after withdraw
        (, _availableRewards) = ext.getStakeInfo(stakerOne);
        assertEq(_availableRewards, ((((block.timestamp - timeOfLastUpdate) * 3) * rewardsPerUnitTime) / timeUnit));

        uint256 timeOfLastUpdateLatest = block.timestamp;

        // check available rewards some time after withdraw
        vm.roll(200);
        vm.warp(2000);

        (, _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            (((((timeOfLastUpdateLatest - timeOfLastUpdate) * 3)) * rewardsPerUnitTime) / timeUnit) +
                (((((block.timestamp - timeOfLastUpdateLatest) * 1)) * rewardsPerUnitTime) / timeUnit)
        );
    }
}
