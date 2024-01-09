// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IDropSinglePhase_V1.sol";
import "../../lib/MerkleProof.sol";
import "../../lib/BitMaps.sol";

abstract contract DropSinglePhase_V1 is IDropSinglePhase_V1 {
    using BitMaps for BitMaps.BitMap;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The active conditions for claiming tokens.
    ClaimCondition public claimCondition;

    /// @dev The ID for the active claim condition.
    bytes32 private conditionId;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Map from an account and uid for a claim condition, to the last timestamp
     *       at which the account claimed tokens under that claim condition.
     */
    mapping(bytes32 => mapping(address => uint256)) private lastClaimTimestamp;

    /**
     *  @dev Map from a claim condition uid to whether an address in an allowlist
     *       has already claimed tokens i.e. used their place in the allowlist.
     */
    mapping(bytes32 => BitMaps.BitMap) private usedAllowlistSpot;

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

        bytes32 activeConditionId = conditionId;

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (bool validMerkleProof, ) = verifyClaimMerkleProof(_dropMsgSender(), _quantity, _allowlistProof);

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the maxQuantityInAllowlist value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being equal/less than the limit
        bool toVerifyMaxQuantityPerTransaction = _allowlistProof.maxQuantityInAllowlist == 0 ||
            claimCondition.merkleRoot == bytes32(0);

        verifyClaim(_dropMsgSender(), _quantity, _currency, _pricePerToken, toVerifyMaxQuantityPerTransaction);

        if (validMerkleProof && _allowlistProof.maxQuantityInAllowlist > 0) {
            /**
             *  Mark the claimer's use of their position in the allowlist. A spot in an allowlist
             *  can be used only once.
             */
            usedAllowlistSpot[activeConditionId].set(uint256(uint160(_dropMsgSender())));
        }

        // Update contract state.
        claimCondition.supplyClaimed += _quantity;
        lastClaimTimestamp[activeConditionId][_dropMsgSender()] = block.timestamp;

        // If there's a price, collect price.
        _collectPriceOnClaim(address(0), _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.
        uint256 startTokenId = _transferTokensOnClaim(_receiver, _quantity);

        emit TokensClaimed(_dropMsgSender(), _receiver, startTokenId, _quantity);

        _afterClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /// @dev Lets a contract admin set claim conditions.
    function setClaimConditions(ClaimCondition calldata _condition, bool _resetClaimEligibility) external override {
        if (!_canSetClaimConditions()) {
            revert("Not authorized");
        }

        bytes32 targetConditionId = conditionId;
        uint256 supplyClaimedAlready = claimCondition.supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), block.number));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        claimCondition = ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerTransaction: _condition.quantityLimitPerTransaction,
            waitTimeInSecondsBetweenClaims: _condition.waitTimeInSecondsBetweenClaims,
            merkleRoot: _condition.merkleRoot,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency
        });
        conditionId = targetConditionId;

        emit ClaimConditionUpdated(_condition, _resetClaimEligibility);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        ClaimCondition memory currentClaimPhase = claimCondition;

        if (_currency != currentClaimPhase.currency || _pricePerToken != currentClaimPhase.pricePerToken) {
            revert("Invalid price or currency");
        }

        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        if (
            _quantity == 0 ||
            (verifyMaxQuantityPerTransaction && _quantity > currentClaimPhase.quantityLimitPerTransaction)
        ) {
            revert("Invalid quantity");
        }

        if (currentClaimPhase.supplyClaimed + _quantity > currentClaimPhase.maxClaimableSupply) {
            revert("exceeds max supply");
        }

        (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp) = getClaimTimestamp(_claimer);
        if (
            currentClaimPhase.startTimestamp > block.timestamp ||
            (lastClaimedAt != 0 && block.timestamp < nextValidClaimTimestamp)
        ) {
            revert("cant claim yet");
        }
    }

    /// @dev Checks whether a claimer meets the claim condition's allowlist criteria.
    function verifyClaimMerkleProof(
        address _claimer,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        ClaimCondition memory currentClaimPhase = claimCondition;

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _allowlistProof.proof,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _allowlistProof.maxQuantityInAllowlist))
            );
            if (!validMerkleProof) {
                revert("not in allowlist");
            }

            if (usedAllowlistSpot[conditionId].get(uint256(uint160(_claimer)))) {
                revert("proof claimed");
            }

            if (_allowlistProof.maxQuantityInAllowlist != 0 && _quantity > _allowlistProof.maxQuantityInAllowlist) {
                revert("Invalid qty proof");
            }
        }
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        address _claimer
    ) public view returns (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp) {
        lastClaimedAt = lastClaimTimestamp[conditionId][_claimer];

        unchecked {
            nextValidClaimTimestamp = lastClaimedAt + claimCondition.waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimedAt) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
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
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual;

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal virtual returns (uint256 startTokenId);

    function _canSetClaimConditions() internal view virtual returns (bool);
}
