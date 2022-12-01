// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Token
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

// Meta transactions
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/PermissionsEnumerable.sol";
import { Staking721Upgradeable } from "../extension/Staking721Upgradeable.sol";

contract NFTStake is
    Initializable,
    ContractMetadata,
    PermissionsEnumerable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    IERC721ReceiverUpgradeable,
    Staking721Upgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("NFTStake");
    uint256 private constant VERSION = 1;

    /// @dev ERC20 Reward Token address. See {_mintRewards} below.
    address public rewardToken;

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _rewardToken,
        address _nftCollection,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init_unchained(_trustedForwarders);

        rewardToken = _rewardToken;
        __Staking721_init(_nftCollection);
        _setTimeUnit(_timeUnit);
        _setRewardsPerUnitTime(_rewardsPerUnitTime);

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
    function withdrawRewardTokens(uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");

        CurrencyTransferLib.transferCurrency(rewardToken, address(this), _msgSender(), _amount);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 logic
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721ReceiverUpgradeable).interfaceId;
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

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
