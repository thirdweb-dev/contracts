// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Staking721 } from "contracts/extension/Staking721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/eip/interface/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { MockERC721 } from "../../mocks/MockERC721.sol";

contract MyStakingContract is ERC20, Staking721, IERC721Receiver {
    bool condition;

    constructor(
        string memory _name,
        string memory _symbol,
        address _nftCollection,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) ERC20(_name, _symbol) Staking721(_nftCollection) {
        condition = true;
        _setStakingCondition(_timeUnit, _rewardsPerUnitTime);
    }

    /// @notice View total rewards available in the staking contract.
    function getRewardTokenBalance() external view override returns (uint256) {}

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 logic
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address, uint256, bytes calldata) external view override returns (bytes4) {
        require(isStaking == 2, "Direct transfer");
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId;
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
        ext = new MyStakingContract("Test Staking Contract", "TSC", address(erc721), timeUnit, rewardsPerUnitTime);

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
        (uint256[] memory _amountStaked, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(_amountStaked.length, _tokenIdsOne.length);
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

        assertEq(_amountStaked.length, _tokenIdsTwo.length);
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

    function test_revert_stake_stakingZeroTokens() public {
        // stake 0 tokens
        uint256[] memory _tokenIds;

        vm.prank(stakerOne);
        vm.expectRevert("Staking 0 tokens");
        ext.stake(_tokenIds);
    }

    function test_revert_stake_notStaker() public {
        // stake unowned tokens
        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = 6;

        vm.prank(stakerOne);
        vm.expectRevert("ERC721: transfer from incorrect owner");
        ext.stake(_tokenIds);
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
        (uint256[] memory _amountStaked, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(_amountStaked.length, _tokenIdsOne.length);
        assertEq(_availableRewards, 0);
    }

    function test_revert_claimRewards_noRewards() public {
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        ext.stake(_tokenIdsOne);

        //=================== try to claim rewards in same block

        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        ext.claimRewards();

        //======= withdraw tokens and claim rewards
        vm.roll(100);
        vm.warp(1000);

        vm.prank(stakerOne);
        ext.withdraw(_tokenIdsOne);
        vm.prank(stakerOne);
        ext.claimRewards();

        //===== try to claim rewards again
        vm.roll(200);
        vm.warp(2000);
        vm.prank(stakerOne);
        vm.expectRevert("No rewards");
        ext.claimRewards();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stake conditions
    //////////////////////////////////////////////////////////////*/

    function test_state_setRewardsPerUnitTime() public {
        // check current value
        assertEq(rewardsPerUnitTime, ext.getRewardsPerUnitTime());

        // set new value and check
        uint256 newRewardsPerUnitTime = 50;
        ext.setRewardsPerUnitTime(newRewardsPerUnitTime);
        assertEq(newRewardsPerUnitTime, ext.getRewardsPerUnitTime());

        //================ stake tokens
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        ext.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        ext.setRewardsPerUnitTime(200);
        assertEq(200, ext.getRewardsPerUnitTime());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * _tokenIdsOne.length) * newRewardsPerUnitTime) / timeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _newRewards,
            _availableRewards + ((((block.timestamp - newTimeOfLastUpdate) * _tokenIdsOne.length) * 200) / timeUnit)
        );
    }

    function test_revert_setRewardsPerUnitTime_notAuthorized() public {
        ext.setCondition(false);

        vm.expectRevert("Not authorized");
        ext.setRewardsPerUnitTime(1);
    }

    function test_state_setTimeUnit() public {
        // check current value
        assertEq(timeUnit, ext.getTimeUnit());

        // set new value and check
        uint256 newTimeUnit = 1 minutes;
        ext.setTimeUnit(newTimeUnit);
        assertEq(newTimeUnit, ext.getTimeUnit());

        //================ stake tokens
        vm.warp(1);
        uint256[] memory _tokenIdsOne = new uint256[](3);
        _tokenIdsOne[0] = 0;
        _tokenIdsOne[1] = 1;
        _tokenIdsOne[2] = 2;

        // stake 3 tokens
        vm.prank(stakerOne);
        ext.stake(_tokenIdsOne);
        uint256 timeOfLastUpdate = block.timestamp;

        //=================== warp timestamp and again set rewardsPerUnitTime
        vm.roll(100);
        vm.warp(1000);

        ext.setTimeUnit(1 seconds);
        assertEq(1 seconds, ext.getTimeUnit());
        uint256 newTimeOfLastUpdate = block.timestamp;

        // check available rewards -- should use previous value for rewardsPerUnitTime for calculation
        (, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _availableRewards,
            ((((block.timestamp - timeOfLastUpdate) * _tokenIdsOne.length) * rewardsPerUnitTime) / newTimeUnit)
        );

        //====== check rewards after some time
        vm.roll(300);
        vm.warp(3000);

        (, uint256 _newRewards) = ext.getStakeInfo(stakerOne);

        assertEq(
            _newRewards,
            _availableRewards +
                ((((block.timestamp - newTimeOfLastUpdate) * _tokenIdsOne.length) * rewardsPerUnitTime) / (1 seconds))
        );
    }

    function test_revert_setTimeUnit_notAuthorized() public {
        ext.setCondition(false);

        vm.expectRevert("Not authorized");
        ext.setTimeUnit(1);
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
        (uint256[] memory _amountStaked, uint256 _availableRewards) = ext.getStakeInfo(stakerOne);

        assertEq(_amountStaked.length, _tokenIdsOne.length);
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

    function test_revert_withdraw_withdrawingZeroTokens() public {
        uint256[] memory _tokensToWithdraw;

        vm.expectRevert("Withdrawing 0 tokens");
        ext.withdraw(_tokensToWithdraw);
    }

    function test_revert_withdraw_notStaker() public {
        // stake tokens
        uint256[] memory _tokenIds = new uint256[](2);
        _tokenIds[0] = 0;
        _tokenIds[1] = 1;

        vm.prank(stakerOne);
        ext.stake(_tokenIds);

        // trying to withdraw zero tokens
        uint256[] memory _tokensToWithdraw = new uint256[](1);
        _tokensToWithdraw[0] = 2;

        vm.prank(stakerOne);
        vm.expectRevert("Not staker");
        ext.withdraw(_tokensToWithdraw);
    }

    function test_revert_withdraw_withdrawingMoreThanStaked() public {
        // stake tokens
        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = 0;

        vm.prank(stakerOne);
        ext.stake(_tokenIds);

        // trying to withdraw tokens not staked by caller
        uint256[] memory _tokensToWithdraw = new uint256[](2);
        _tokensToWithdraw[0] = 0;
        _tokensToWithdraw[1] = 1;

        vm.prank(stakerOne);
        vm.expectRevert("Withdrawing more than staked");
        ext.withdraw(_tokensToWithdraw);
    }
}
