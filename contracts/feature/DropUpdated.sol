// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IDropUpdated.sol";
import "../lib/MerkleProof.sol";
import "../lib/TWBitMaps.sol";

abstract contract DropUpdated is IDropUpdated {
    using TWBitMaps for TWBitMaps.BitMap;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The active conditions for claiming tokens.
    // ClaimConditionList public claimCondition;

    /// @dev Mapping from token ID => the set of all claim conditions, at any given moment, for tokens of the token ID.
    mapping(uint256 => ClaimConditionList) public claimCondition;

    /*///////////////////////////////////////////////////////////////
                            Claim logic
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
        _claim(_receiver, type(uint256).max, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) external payable {
        _claim(_receiver, _tokenId, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    function _claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal {
        _beforeClaim(_receiver, _tokenId, _quantity, _currency, _pricePerToken, _allowlistProof, _data);

        // Get the active claim condition index.
        uint256 activeConditionId = _activeClaimConditionId(_tokenId);
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId].conditions[activeConditionId];

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (bool validMerkleProof, uint256 merkleProofIndex) = _verifyClaimMerkleProof(
            activeConditionId,
            _dropMsgSender(),
            _tokenId,
            _quantity,
            _allowlistProof
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the maxQuantityInAllowlist value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being equal/less than the limit
        bool toVerifyMaxQuantityPerTransaction = _allowlistProof.maxQuantityInAllowlist == 0 ||
            currentClaimPhase.merkleRoot == bytes32(0);

        verifyClaim(
            activeConditionId,
            _dropMsgSender(),
            _tokenId,
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
            claimCondition[_tokenId].usedAllowlistSpot[activeConditionId].set(merkleProofIndex);
        }

        // Update contract state.
        claimCondition[_tokenId].conditions[activeConditionId].supplyClaimed += _quantity;
        claimCondition[_tokenId].lastClaimTimestamp[activeConditionId][_dropMsgSender()] = block.timestamp;

        // If there's a price, collect price.
        collectPriceOnClaim(_quantity, _currency, _pricePerToken, _tokenId);

        // Mint the relevant NFTs to claimer.
        uint256 startTokenId = transferTokensOnClaim(_receiver, _tokenId, _quantity);

        emit TokensClaimed(activeConditionId, _dropMsgSender(), _receiver, startTokenId, _quantity);

        _afterClaim(_receiver, _tokenId, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /*///////////////////////////////////////////////////////////////
                            Claim verification
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        _verifyClaim(
            _conditionId, 
            _claimer, 
            type(uint256).max, 
            _quantity, 
            _currency, 
            _pricePerToken, 
            verifyMaxQuantityPerTransaction);
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        _verifyClaim(
            _conditionId, 
            _claimer, 
            _tokenId, 
            _quantity, 
            _currency, 
            _pricePerToken, 
            verifyMaxQuantityPerTransaction);
    }

    function _verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) internal view {
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId].conditions[_conditionId];

        if (_currency != currentClaimPhase.currency || _pricePerToken != currentClaimPhase.pricePerToken) {
            revert Drop__InvalidCurrencyOrPrice(
                _currency,
                currentClaimPhase.currency,
                _pricePerToken,
                currentClaimPhase.pricePerToken
            );
        }

        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        if (
            _quantity == 0 ||
            (verifyMaxQuantityPerTransaction && _quantity > currentClaimPhase.quantityLimitPerTransaction)
        ) {
            revert Drop__InvalidQuantity();
        }

        if (currentClaimPhase.supplyClaimed + _quantity > currentClaimPhase.maxClaimableSupply) {
            revert Drop__ExceedMaxClaimableSupply(
                currentClaimPhase.supplyClaimed,
                currentClaimPhase.maxClaimableSupply
            );
        }

        // require(
        //     maxTotalSupply[_tokenId] == 0 || totalSupply[_tokenId] + _quantity <= maxTotalSupply[_tokenId],
        //     "exceed max total supply"
        // );
        // require(
        //     maxWalletClaimCount[_tokenId] == 0 ||
        //         walletClaimCount[_tokenId][_claimer] + _quantity <= maxWalletClaimCount[_tokenId],
        //     "exceed claim limit for wallet"
        // );

        (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp) = _claimTimestamp(_tokenId, _conditionId, _claimer);
        if (
            currentClaimPhase.startTimestamp > block.timestamp ||
            (lastClaimedAt != 0 && block.timestamp < nextValidClaimTimestamp)
        ) {
            revert Drop__CannotClaimYet(
                block.timestamp,
                currentClaimPhase.startTimestamp,
                lastClaimedAt,
                nextValidClaimTimestamp
            );
        }
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(uint256 _conditionId, address _claimer)
        public
        view
        returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp)
    {
        return _claimTimestamp(type(uint256).max, _conditionId, _claimer);
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        return _claimTimestamp(_tokenId, _conditionId, _claimer);
    }

    function _claimTimestamp(
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) internal view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimCondition[_tokenId].lastClaimTimestamp[_conditionId][_claimer];

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimCondition[_tokenId].conditions[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Merkle proof verification
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether a claimer meets the claim condition's allowlist criteria.
    function verifyClaimMerkleProof(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        return _verifyClaimMerkleProof(_conditionId, _claimer, type(uint256).max, _quantity, _allowlistProof);
    }

    /// @dev Checks whether a claimer meets the claim condition's allowlist criteria, for a given tokenId
    function verifyClaimMerkleProof(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        return _verifyClaimMerkleProof(_conditionId, _claimer, _tokenId, _quantity, _allowlistProof);
    }

    function _verifyClaimMerkleProof(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) internal view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId].conditions[_conditionId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _allowlistProof.proof,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _allowlistProof.maxQuantityInAllowlist))
            );
            if (!validMerkleProof) {
                revert Drop__NotInWhitelist();
            }

            if (claimCondition[_tokenId].usedAllowlistSpot[_conditionId].get(merkleProofIndex)) {
                revert Drop__ProofClaimed();
            }

            if (_allowlistProof.maxQuantityInAllowlist != 0 && _quantity > _allowlistProof.maxQuantityInAllowlist) {
                revert Drop__InvalidQuantityProof(_allowlistProof.maxQuantityInAllowlist);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Set/get claim conditions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _conditions, bool _resetClaimEligibility)
        external
        virtual
        override
    {
        if (!_canSetClaimConditions()) {
            revert Drop__NotAuthorized();
        }

        _setClaimConditions(claimCondition[type(uint256).max], _conditions, _resetClaimEligibility);

        emit ClaimConditionsUpdated(_conditions, _resetClaimEligibility);
    }

    /// @dev Lets a contract admin set claim conditions, for a tokenId.
    function setClaimConditions(
        uint256 _tokenId,
        ClaimCondition[] calldata _conditions,
        bool _resetClaimEligibility
    ) external virtual override
    {
        if (!_canSetClaimConditions()) {
            revert Drop__NotAuthorized();
        }

        // require(_tokenId != type(uint256).max, "invalid token id");

        _setClaimConditions(claimCondition[_tokenId], _conditions, _resetClaimEligibility);

        emit ClaimConditionsUpdated(_conditions, _tokenId, _resetClaimEligibility);
    }

    /// @dev At any given moment, returns the uid for the active claim condition.
    function getActiveClaimConditionId() public view returns (uint256) {
        return _activeClaimConditionId(type(uint256).max);
    }

    /// @dev At any given moment, returns the uid for the active claim condition, for a given tokenId.
    function getActiveClaimConditionId(uint256 _tokenId) public view returns (uint256) {
        return _activeClaimConditionId(_tokenId);
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _conditionId) external view returns (ClaimCondition memory condition) {
        condition = claimCondition[type(uint256).max].conditions[_conditionId];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set claim conditions.
    function _setClaimConditions(
        ClaimConditionList storage claimConditionList,
        ClaimCondition[] calldata _conditions,
        bool _resetClaimEligibility
    ) internal
    {

        uint256 existingStartIndex = claimConditionList.currentStartId;
        uint256 existingPhaseCount = claimConditionList.count;

        /**
         *  `lastClaimTimestamp` and `usedAllowListSpot` are mappings that use a
         *  claim condition's UID as a key.
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_conditions`, effectively resetting the restrictions on claims expressed
         *  by `lastClaimTimestamp` and `usedAllowListSpot`.
         */
        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        claimConditionList.count = _conditions.length;
        claimConditionList.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        for (uint256 i = 0; i < _conditions.length; i++) {
            require(i == 0 || lastConditionStartTimestamp < _conditions[i].startTimestamp, "ST");

            uint256 supplyClaimedAlready = claimConditionList.conditions[newStartIndex + i].supplyClaimed;
            if (supplyClaimedAlready > _conditions[i].maxClaimableSupply) {
                revert Drop__MaxSupplyClaimedAlready(supplyClaimedAlready);
            }

            claimConditionList.conditions[newStartIndex + i] = _conditions[i];
            claimConditionList.conditions[newStartIndex + i].supplyClaimed = supplyClaimedAlready;

            lastConditionStartTimestamp = _conditions[i].startTimestamp;
        }

        /**
         *  Gas refunds (as much as possible)
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_conditions`. So, we delete claim conditions with UID < `newStartIndex`.
         *
         *  If `_resetClaimEligibility == false`, and there are more existing claim conditions
         *  than in `_conditions`, we delete the existing claim conditions that don't get replaced
         *  by the conditions in `_conditions`.
         */
        if (_resetClaimEligibility) {
            for (uint256 i = existingStartIndex; i < newStartIndex; i++) {
                delete claimConditionList.conditions[i];
                delete claimConditionList.usedAllowlistSpot[i];
            }
        } else {
            if (existingPhaseCount > _conditions.length) {
                for (uint256 i = _conditions.length; i < existingPhaseCount; i++) {
                    delete claimConditionList.conditions[newStartIndex + i];
                    delete claimConditionList.usedAllowlistSpot[newStartIndex + i];
                }
            }
        }
    }

    /// @dev At any given moment, returns the uid for the active claim condition, for a given tokenId.
    function _activeClaimConditionId(uint256 _tokenId) internal view returns (uint256) {
        ClaimConditionList storage claimConditionList = claimCondition[_tokenId];
        for (uint256 i = claimConditionList.currentStartId + claimConditionList.count; i > claimConditionList.currentStartId; i--) {
            if (block.timestamp >= claimConditionList.conditions[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("!CONDITION.");
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
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual {}

    /// @dev Runs after every `claim` function call.
    function _afterClaim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof,
        bytes memory _data
    ) internal virtual {}

    /*///////////////////////////////////////////////////////////////
        Virtual functions: to be implemented in derived contract
    //////////////////////////////////////////////////////////////*/

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        uint256 _tokenId
    ) internal virtual;

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(address _to, uint256 _tokenId, uint256 _quantityBeingClaimed)
        internal
        virtual
        returns (uint256 startTokenId);

    /// @dev Determine what wallet can update claim conditions
    function _canSetClaimConditions() internal virtual returns (bool);
}