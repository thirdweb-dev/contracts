// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Meta transactions
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { CurrencyTransferLib } from "../lib/CurrencyTransferLib.sol";
import "../eip/interface/IERC20Metadata.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/PermissionsEnumerable.sol";
import { Staking20Upgradeable } from "../extension/Staking20Upgradeable.sol";

contract TokenStake is
    Initializable,
    ContractMetadata,
    PermissionsEnumerable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    Staking20Upgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("TokenStake");
    uint256 private constant VERSION = 1;

    /// @dev Emitted when contract admin withdraws reward tokens.
    event RewardTokensWithdrawnByAdmin(uint256 _amount);

    /// @dev ERC20 Reward Token address. See {_mintRewards} below.
    address public rewardToken;

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _rewardToken,
        address _stakingToken,
        uint256 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator
    ) external initializer {
        __ERC2771Context_init_unchained(_trustedForwarders);

        require(_rewardToken != _stakingToken, "Reward Token and Staking Token can't be same.");
        rewardToken = _rewardToken;
        __Staking20_init(
            _stakingToken,
            IERC20Metadata(_stakingToken).decimals(),
            IERC20Metadata(_rewardToken).decimals()
        );
        _setStakingCondition(_timeUnit, _rewardRatioNumerator, _rewardRatioDenominator);

        _setupContractURI(_contractURI);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /// @dev Returns the module type of the contract.
    function contractType() external pure virtual returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure virtual returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev Admin can withdraw excess reward tokens.
    function withdrawRewardTokens(uint256 _amount) external nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");

        CurrencyTransferLib.transferCurrency(rewardToken, address(this), _msgSender(), _amount);

        // The withdrawal shouldn't reduce staking token balance. `>=` accounts for any accidental transfers.
        require(IERC20(token).balanceOf(address(this)) >= stakingTokenBalance, "Staking token balance reduced.");

        emit RewardTokensWithdrawnByAdmin(_amount);
    }

    /// @notice View total rewards available in the staking contract.
    function getRewardTokenBalance() external view override returns (uint256 _rewardsAvailableInContract) {
        return IERC20(rewardToken).balanceOf(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                        Transfer Staking Rewards
    //////////////////////////////////////////////////////////////*/

    /// @dev Mint/Transfer ERC20 rewards to the staker.
    function _mintRewards(address _staker, uint256 _rewards) internal override {
        CurrencyTransferLib.transferCurrency(rewardToken, address(this), _staker, _rewards);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether staking related restrictions can be set in the given execution context.
    function _canSetStakeConditions() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _stakeMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
