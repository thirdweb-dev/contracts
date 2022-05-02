// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IDropSinglePhase.sol";
import "../lib/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

abstract contract DropSinglePhase is IDropSinglePhase {

    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    /// @dev The active conditions for claiming lazy minted tokens.
    ClaimCondition public claimCondition;

    mapping(bytes32 => mapping(address => uint256)) private lastClaimTimestamp;
    mapping(bytes32 => BitMapsUpgradeable.BitMap) private usedAllowlistSpot;

    /// @dev The ID for the active claim condition.
    bytes32 private conditionId;

    function _msgSender() internal virtual returns (address) {
        return msg.sender;
    }

    function _beforeClaim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual;

    function _afterClaim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual;

    /// @dev Lets an account claim NFTs.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) external payable virtual {

        _beforeClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        bytes32 activeConditionId = conditionId;
        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (bool validMerkleProof, uint256 merkleProofIndex) = verifyClaimMerkleProof(
            _msgSender(),
            _quantity,
            _allowlistProof
        );

        // Verify claim validity. If not valid, revert.
        bool toVerifyMaxQuantityPerTransaction = _allowlistProof.maxQuantityInAllowlist == 0;

        verifyClaim(
            _msgSender(),
            _quantity,
            _currency,
            _pricePerToken,
            toVerifyMaxQuantityPerTransaction
        );

        if (validMerkleProof && _allowlistProof.maxQuantityInAllowlist > 0) {
            /**
             *  Mark the claimer's use of their position in the allowlist. A spot in an allowlist
             *  can be used only once.
             */
            usedAllowlistSpot[activeConditionId].set(merkleProofIndex);
        }

        // Update contract state.
        claimCondition.supplyClaimed += _quantity;
        lastClaimTimestamp[activeConditionId][_msgSender()] = block.timestamp;

        // If there's a price, collect price.
        collectPrice(_quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.
        uint256 startTokenId = transferClaimedTokens(_receiver, _quantity);

        emit TokensClaimed(claimCondition, _msgSender(), _receiver, _quantity, startTokenId);

        _afterClaim(_receiver, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPrice(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual;

    /// @dev Transfers the NFTs being claimed.
    function transferClaimedTokens(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal virtual returns (uint256 startTokenId);

    function setClaimCondition(ClaimCondition calldata _condition, bool _resetClaimEligibility)
        external
    {
        if (_resetClaimEligibility) {
            conditionId = keccak256(abi.encodePacked(msg.sender, block.number));
        }

        ClaimCondition memory currentConditoin = claimCondition;

        claimCondition = ClaimCondition({
            startTimestamp: block.timestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: _resetClaimEligibility ? currentConditoin.supplyClaimed : _condition.supplyClaimed,
            quantityLimitPerTransaction: _condition.supplyClaimed,
            waitTimeInSecondsBetweenClaims: _condition.waitTimeInSecondsBetweenClaims,
            merkleRoot: _condition.merkleRoot,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency
        });

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

        require(
            _currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken,
            "invalid currency or price."
        );

        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        require(
            _quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction),
            "invalid quantity."
        );
        require(
            currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply,
            "exceed max claimable supply."
        );
        // require(nextTokenIdToClaim + _quantity <= nextTokenIdToMint, "not enough minted tokens.");
        // require(maxTotalSupply == 0 || nextTokenIdToClaim + _quantity <= maxTotalSupply, "exceed max total supply.");
        // require(
        //     maxWalletClaimCount == 0 || walletClaimCount[_claimer] + _quantity <= maxWalletClaimCount,
        //     "exceed claim limit"
        // );

        uint256 timestampOfLastClaim = lastClaimTimestamp[conditionId][_claimer];
        require(timestampOfLastClaim == 0 || block.timestamp >= timestampOfLastClaim + currentClaimPhase.waitTimeInSecondsBetweenClaims, "cannot claim.");
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
            require(validMerkleProof, "not in whitelist.");
            require(!usedAllowlistSpot[conditionId].get(merkleProofIndex), "proof claimed.");
            require(
                _allowlistProof.maxQuantityInAllowlist == 0 || _quantity <= _allowlistProof.maxQuantityInAllowlist,
                "invalid quantity proof."
            );
        }
    }

}