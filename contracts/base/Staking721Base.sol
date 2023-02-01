// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Staking721.sol";

import "../eip/ERC165.sol";
import "../eip/interface/IERC20.sol";
import "../eip/interface/IERC721Receiver.sol";

/**
 *
 *  EXTENSION: Staking721
 *
 *  The `Staking721Base` smart contract implements NFT staking mechanism.
 *  Allows users to stake their ERC-721 NFTs and earn rewards in form of ERC-20 tokens.
 *
 *  Following features and implementation setup must be noted:
 *
 *      - ERC-721 NFTs from only one NFT collection can be staked.
 *
 *      - Contract admin can choose to give out rewards by either transferring or minting the rewardToken,
 *        which is an ERC20 token. See {_mintRewards}.
 *
 *      - To implement custom logic for staking, reward calculation, etc. corresponding functions can be
 *        overridden from the extension `Staking721`.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically.
 *
 */

/// note: This contract is provided as a base contract only.
//        This is to support a variety of use-cases that can be build on top of this base.
//
//        Any additional functionality such as deposit functions, reward-minting, etc.
//        must be implemented by the deployer of this contract, as needed for their use-case.

contract Staking721Base is ContractMetadata, Multicall, Ownable, Staking721, ERC165, IERC721Receiver {
    /// @dev ERC20 Reward Token address. See {_mintRewards} below.
    address public rewardToken;

    constructor(
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime,
        address _stakingToken,
        address _rewardToken
    ) Staking721(_stakingToken) {
        _setupOwner(msg.sender);
        _setStakingCondition(_timeUnit, _rewardsPerUnitTime);

        rewardToken = _rewardToken;
    }

    /// @notice View total rewards available in the staking contract.
    function getRewardTokenBalance() external view virtual override returns (uint256 _rewardsAvailableInContract) {
        return IERC20(rewardToken).balanceOf(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 logic
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        require(isStaking == 2, "Direct transfer");
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                        Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev    Mint ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for which to calculated rewards.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     */
    function _mintRewards(address _staker, uint256 _rewards) internal virtual override {
        // Mint or transfer reward-tokens here.
        // e.g.
        //
        // IERC20(rewardToken).transfer(_staker, _rewards);
        //
        // OR
        //
        // Use a mintable ERC20, such as thirdweb's `TokenERC20.sol`
        //
        // TokenERC20(rewardToken).mintTo(_staker, _rewards);
        // note: The staking contract should have minter role to mint tokens.
    }

    /*//////////////////////////////////////////////////////////////
                        Other Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether staking restrictions can be set in given execution context.
    function _canSetStakeConditions() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
