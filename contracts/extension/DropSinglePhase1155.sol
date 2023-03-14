// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IDropSinglePhase1155.sol";
import "../lib/MerkleProof.sol";

abstract contract DropSinglePhase1155 is IDropSinglePhase1155 {
    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from tokenId => active claim condition for the tokenId.
    mapping(uint256 => ClaimCondition) public claimCondition;

    /// @dev Mapping from tokenId => active claim condition's UID.
    mapping(uint256 => bytes32) private conditionId;

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
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) public payable virtual override {
        _beforeClaim(_tokenId, _receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        ClaimCondition memory condition = claimCondition[_tokenId];
        bytes32 activeConditionId = conditionId[_tokenId];

        verifyClaim(_tokenId, _dropMsgSender(), _quantity, _currency, _pricePerToken, _allowlistProof);

        // Update contract state.
        condition.supplyClaimed += _quantity;
        supplyClaimedByWallet[activeConditionId][_dropMsgSender()] += _quantity;
        claimCondition[_tokenId] = condition;

        // If there's a price, collect price.
        _collectPriceOnClaim(address(0), _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.
        _transferTokensOnClaim(_receiver, _tokenId, _quantity);

        emit TokensClaimed(_dropMsgSender(), _receiver, _tokenId, _quantity);

        _afterClaim(_tokenId, _receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /// @dev Lets a contract admin set claim conditions.
    function setClaimConditions(
        uint256 _tokenId,
        ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external override {
        if (!_canSetClaimConditions()) {
            revert("Not authorized");
        }

        ClaimCondition memory condition = claimCondition[_tokenId];
        bytes32 targetConditionId = conditionId[_tokenId];

        uint256 supplyClaimedAlready = condition.supplyClaimed;

        if (targetConditionId == bytes32(0) || _resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), block.number, _tokenId));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        ClaimCondition memory updatedCondition = ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerWallet: _condition.quantityLimitPerWallet,
            merkleRoot: _condition.merkleRoot,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency,
            metadata: _condition.metadata
        });

        claimCondition[_tokenId] = updatedCondition;
        conditionId[_tokenId] = targetConditionId;

        emit ClaimConditionUpdated(_tokenId, _condition, _resetClaimEligibility);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _tokenId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof
    ) public view returns (bool isOverride) {
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId];
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
            claimLimit = _allowlistProof.quantityLimitPerWallet != 0
                ? _allowlistProof.quantityLimitPerWallet
                : claimLimit;
            claimPrice = _allowlistProof.pricePerToken != type(uint256).max
                ? _allowlistProof.pricePerToken
                : claimPrice;
            claimCurrency = _allowlistProof.pricePerToken != type(uint256).max && _allowlistProof.currency != address(0)
                ? _allowlistProof.currency
                : claimCurrency;
        }

        uint256 _supplyClaimedByWallet = supplyClaimedByWallet[conditionId[_tokenId]][_claimer];

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
    function getSupplyClaimedByWallet(uint256 _tokenId, address _claimer) public view returns (uint256) {
        return supplyClaimedByWallet[conditionId[_tokenId]][_claimer];
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
        uint256 _tokenId,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual {}

    /// @dev Runs after every `claim` function call.
    function _afterClaim(
        uint256 _tokenId,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual {}

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual;

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(
        address _to,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal virtual;

    function _canSetClaimConditions() internal view virtual returns (bool);
}
