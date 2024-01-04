// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import "./TWFactory.sol";
import "./interface/ITWFee.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Multicall } from "../extension/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

interface IFeeTierPlacementExtension {
    /// @dev Returns the fee tier for a given proxy contract address and proxy deployer address.
    function getFeeTier(
        address deployer,
        address proxy
    ) external view returns (uint128 tierId, uint128 validUntilTimestamp);
}

contract TWFee is ITWFee, Multicall, ERC2771Context, AccessControlEnumerable, IFeeTierPlacementExtension {
    /// @dev The factory for deploying contracts.
    TWFactory public immutable factory;

    /// @dev The maximum threshold for fees. 1%
    uint256 public constant MAX_FEE_BPS = 100;

    /// @dev TIER_FEE_ROLE holders can create tiers.
    bytes32 private constant TIER_FEE_ROLE = keccak256("TIER_FEE_ROLE");

    /// @dev TIER_CONTROLLER_ROLE holders can assign tiers to deployer or proxy.
    bytes32 private constant TIER_CONTROLLER_ROLE = keccak256("TIER_CONTROLLER_ROLE");

    /// @dev Mapping from proxy contract or proxy deployer address => pricing tier.
    mapping(address => Tier) private tier;

    /// @dev Mapping from pricing tier id => Fee Type (lib/FeeType.sol) => FeeInfo
    mapping(uint256 => mapping(uint256 => FeeInfo)) public feeInfo;

    /// @dev If we want to extend the logic for fee tier placement, we
    /// could easily points it to a different extension implementation.
    IFeeTierPlacementExtension public tierPlacementExtension;

    struct Tier {
        uint128 id;
        uint128 validUntilTimestamp;
    }

    struct FeeInfo {
        uint256 bps;
        address recipient;
    }

    /// @dev Events
    event TierUpdated(address indexed proxyOrDeployer, uint256 tierId, uint256 validUntilTimestamp);
    event FeeTierUpdated(uint256 indexed tierId, uint256 indexed feeType, address recipient, uint256 bps);

    constructor(address _trustedForwarder, address _factory) ERC2771Context(_trustedForwarder) {
        factory = TWFactory(_factory);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TIER_FEE_ROLE, _msgSender());
        _setupRole(TIER_CONTROLLER_ROLE, _msgSender());
    }

    function setFeeTierPlacementExtension(address _extension) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tierPlacementExtension = IFeeTierPlacementExtension(_extension);
    }

    /// @dev Returns the fee tier for a proxy deployer wallet or contract address.
    function getFeeTier(
        address _deployer,
        address _proxy
    ) public view override returns (uint128 tierId, uint128 validUntilTimestamp) {
        Tier memory targetTier = tier[_proxy];
        if (block.timestamp <= targetTier.validUntilTimestamp) {
            tierId = targetTier.id;
            validUntilTimestamp = targetTier.validUntilTimestamp;
        } else {
            tierId = 0;
            validUntilTimestamp = 0;
        }

        // if the proxy doesn't have a tier, then look up the deployer's tier
        if (tierId == 0 && validUntilTimestamp == 0) {
            targetTier = tier[_deployer];
            if (block.timestamp <= targetTier.validUntilTimestamp) {
                tierId = targetTier.id;
                validUntilTimestamp = targetTier.validUntilTimestamp;
            } else {
                tierId = 0;
                validUntilTimestamp = 0;
            }
        }
    }

    /// @dev Returns the fee info for a given module and fee type.
    function getFeeInfo(address _proxy, uint256 _feeType) external view returns (address recipient, uint256 bps) {
        address deployer = factory.deployer(_proxy);
        uint128 tierId = 0;
        uint128 validUntilTimestamp = 0;

        if (address(tierPlacementExtension) != address(0)) {
            // https://github.com/crytic/slither/issues/982
            // slither-disable-next-line unused-return
            try tierPlacementExtension.getFeeTier(deployer, _proxy) returns (
                // slither-disable-next-line uninitialized-local,variable-scope
                uint128 retTierId,
                // slither-disable-next-line uninitialized-local,variable-scope
                uint128 retValidUntilTimestamp
            ) {
                tierId = retTierId;
                validUntilTimestamp = retValidUntilTimestamp;
                // solhint-disable-next-line no-empty-blocks
            } catch {}
        }

        // if extension doesn't return a tier, then we fetch the local states
        if (tierId == 0 && validUntilTimestamp == 0) {
            (tierId, ) = getFeeTier(deployer, _proxy);
        }

        FeeInfo memory targetFeeInfo = feeInfo[tierId][_feeType];
        (recipient, bps) = (targetFeeInfo.recipient, targetFeeInfo.bps);
    }

    /// @dev Lets a TIER_CONTROLLER_ROLE holder assign a tier to a proxy deployer.
    function setTier(
        address _proxyOrDeployer,
        uint128 _tierId,
        uint128 _validUntilTimestamp
    ) external onlyRole(TIER_CONTROLLER_ROLE) {
        tier[_proxyOrDeployer] = Tier({ id: _tierId, validUntilTimestamp: _validUntilTimestamp });

        emit TierUpdated(_proxyOrDeployer, _tierId, _validUntilTimestamp);
    }

    /// @dev Lets the admin set fee bps and recipient for the given pricing tier and fee type.
    function setFeeInfoForTier(
        uint256 _tierId,
        uint256 _feeBps,
        address _feeRecipient,
        uint256 _feeType
    ) external onlyRole(TIER_FEE_ROLE) {
        require(_feeBps <= MAX_FEE_BPS, "fee too high.");

        FeeInfo memory feeInfoToSet = FeeInfo({ bps: _feeBps, recipient: _feeRecipient });
        feeInfo[_tierId][_feeType] = feeInfoToSet;

        emit FeeTierUpdated(_tierId, _feeType, _feeRecipient, _feeBps);
    }

    //  =====   Getters   =====

    function _msgSender() internal view virtual override(Context, ERC2771Context, Multicall) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
