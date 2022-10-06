// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../extension/interface/IClaimCondition.sol";
import "../lib/MerkleProof.sol";

interface IDropWithTiers is IClaimCondition {
    struct AllowlistProof {
        bytes32[] proof;
        uint256 quantityLimitPerWallet;
        uint256 pricePerToken;
        address currency;
    }

    struct ClaimConditionForTier {
        string tier;
        ClaimCondition condition;
    }

    /// @dev Emitted when tokens are claimed via `claim`.
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        string indexed tier,
        uint256 startTokenId,
        uint256 quantityClaimed
    );

    /// @dev Emitted when the contract's claim conditions are updated.
    event ClaimConditionUpdated(ClaimConditionForTier condition, bool resetEligibility);

    function claim(
        address receiver,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        AllowlistProof calldata allowlistProof,
        bytes memory data
    ) external payable;

    function setClaimConditions(ClaimConditionForTier memory condition, bool _resetClaimEligibility) external;
}

abstract contract DropWithTiers is IDropWithTiers {
    /*///////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from claim condition uid => claim condition.
    mapping(bytes32 => ClaimCondition) private claimConditionForUID;

    /// @dev Mapping from a tier name => conditionId.
    mapping(string => bytes32) private activeConditionIdForTier;

    /**
     *  @dev Map from a claim condition uid and account to supply claimed by account.
     */
    mapping(bytes32 => mapping(address => uint256)) private supplyClaimedByWallet;

    /*///////////////////////////////////////////////////////////////
                            Drop logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account claim tokens.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) public payable virtual override {
        _beforeClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        string memory tier = abi.decode(_data, (string));
        bytes32 activeConditionId = activeConditionIdForTier[tier];

        verifyClaim(_dropMsgSender(), _quantity, _currency, _pricePerToken, _allowlistProof, tier);

        // Update contract state.
        claimConditionForUID[activeConditionId].supplyClaimed += _quantity;
        supplyClaimedByWallet[activeConditionId][_dropMsgSender()] += _quantity;

        // If there's a price, collect price.
        collectPriceOnClaim(address(0), _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.
        uint256 startTokenId = transferTokensOnClaim(_receiver, _quantity, tier);

        emit TokensClaimed(_dropMsgSender(), _receiver, tier, startTokenId, _quantity);

        _afterClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /// @dev Lets an authorized wallet set a claim condition for a tier.
    function setClaimConditions(ClaimConditionForTier memory _conditionForTier, bool _resetClaimEligibility) external {
        if (!_canSetClaimConditions()) {
            revert("Not authorized");
        }

        string memory tier = _conditionForTier.tier;
        bytes32 currentConditionId = activeConditionIdForTier[tier];
        ClaimCondition memory currentCondition = claimConditionForUID[currentConditionId];

        bytes32 targetConditionId = currentConditionId;
        uint256 supplyClaimedAlready = currentCondition.supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), block.number));
        }

        if (supplyClaimedAlready > _conditionForTier.condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        claimConditionForUID[targetConditionId] = ClaimCondition({
            startTimestamp: _conditionForTier.condition.startTimestamp,
            maxClaimableSupply: _conditionForTier.condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerWallet: _conditionForTier.condition.quantityLimitPerWallet,
            merkleRoot: _conditionForTier.condition.merkleRoot,
            pricePerToken: _conditionForTier.condition.pricePerToken,
            currency: _conditionForTier.condition.currency
        });

        activeConditionIdForTier[tier] = targetConditionId;

        emit ClaimConditionUpdated(_conditionForTier, _resetClaimEligibility);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        string memory tier
    ) public view {
        bytes32 activeConditionId = activeConditionIdForTier[tier];
        ClaimCondition memory currentClaimPhase = claimConditionForUID[activeConditionId];

        bool isOverride;
        uint256 claimLimit = currentClaimPhase.quantityLimitPerWallet;
        uint256 claimPrice = currentClaimPhase.pricePerToken;
        address claimCurrency = currentClaimPhase.currency;

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (isOverride, ) = MerkleProof.verify(
                _allowlistProof.proof,
                currentClaimPhase.merkleRoot,
                keccak256(
                    abi.encodePacked(
                        _claimer,
                        _allowlistProof.quantityLimitPerWallet,
                        _allowlistProof.pricePerToken,
                        _allowlistProof.currency
                    )
                )
            );
        }

        if (isOverride) {
            claimLimit = _allowlistProof.quantityLimitPerWallet != type(uint256).max
                ? _allowlistProof.quantityLimitPerWallet
                : claimLimit;
            claimPrice = _allowlistProof.pricePerToken != type(uint256).max
                ? _allowlistProof.pricePerToken
                : claimPrice;
            claimCurrency = _allowlistProof.pricePerToken != type(uint256).max && _allowlistProof.currency != address(0)
                ? _allowlistProof.currency
                : claimCurrency;
        }

        uint256 _supplyClaimedByWallet = supplyClaimedByWallet[activeConditionId][_claimer];

        if (_currency != claimCurrency || _pricePerToken != claimPrice) {
            revert("!PriceOrCurrency");
        }

        if (_quantity == 0 || (_quantity + _supplyClaimedByWallet > claimLimit)) {
            revert("!Qty");
        }

        if (currentClaimPhase.supplyClaimed + _quantity > currentClaimPhase.maxClaimableSupply) {
            revert("!MaxSupply");
        }

        if (currentClaimPhase.startTimestamp > block.timestamp) {
            revert("cant claim yet");
        }
    }

    /// @dev Returns the supply claimed by claimer for active conditionId.
    function getSupplyClaimedByWallet(address _claimer, string memory _tier) public view returns (uint256) {
        bytes32 activeConditionId = activeConditionIdForTier[_tier];
        return supplyClaimedByWallet[activeConditionId][_claimer];
    }

    /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

    /// @dev Exposes the ability to override the msg sender.
    function _dropMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual {}

    /// @dev Runs after every `claim` function call.
    function _afterClaim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual {}

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual;

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed,
        string memory _tier
    ) internal virtual returns (uint256 startTokenId);

    function _canSetClaimConditions() internal view virtual returns (bool);
}
