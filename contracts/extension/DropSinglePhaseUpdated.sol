// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IDropSinglePhaseUpdated.sol";
import "../lib/MerkleProof.sol";
import "../lib/TWBitMaps.sol";

abstract contract DropSinglePhaseUpdated is IDropSinglePhaseUpdated {
    using TWBitMaps for TWBitMaps.BitMap;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // /// @dev The ID for the active claim condition.
    // bytes32 private conditionId;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Map from a token ID to the ID for the active claim condition.
     */
    mapping(uint256 => bytes32) private conditionId;

    /**
     * @dev Mapping from token ID => the claim condition,
     *      at any given moment, for tokens of the token ID.
     */
    mapping(uint256 => ClaimCondition) public claimCondition;

    /**
     *  @dev Map from an account and uid for a claim condition, to the last timestamp
     *       at which the account claimed tokens under that claim condition.
     */
    mapping(bytes32 => mapping(address => uint256)) private lastClaimTimestamp;

    /**
     *  @dev Map from a claim condition uid to whether an address in an allowlist
     *       has already claimed tokens i.e. used their place in the allowlist.
     */
    mapping(bytes32 => TWBitMaps.BitMap) private usedAllowlistSpot;

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

        bytes32 activeConditionId = conditionId[_tokenId];
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId];

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        (bool validMerkleProof, uint256 merkleProofIndex) = _verifyClaimMerkleProof(
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
            usedAllowlistSpot[activeConditionId].set(merkleProofIndex);
        }

        // Update contract state.
        claimCondition[_tokenId].supplyClaimed += _quantity;
        lastClaimTimestamp[activeConditionId][_dropMsgSender()] = block.timestamp;

        // If there's a price, collect price.
        collectPriceOnClaim(_quantity, _currency, _pricePerToken, _tokenId);

        // Mint the relevant NFTs to claimer.
        uint256 startTokenId = transferTokensOnClaim(_receiver, _tokenId, _quantity);

        emit TokensClaimed(_dropMsgSender(), _receiver, startTokenId, _quantity);

        _afterClaim(_receiver, _tokenId, _quantity, _currency, _pricePerToken, _allowlistProof, _data);
    }

    /*///////////////////////////////////////////////////////////////
                            Claim verification
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        _verifyClaim(
            _claimer,
            type(uint256).max,
            _quantity,
            _currency,
            _pricePerToken,
            verifyMaxQuantityPerTransaction
        );
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        _verifyClaim(_claimer, _tokenId, _quantity, _currency, _pricePerToken, verifyMaxQuantityPerTransaction);
    }

    function _verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) internal view {
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId];

        if (_currency != currentClaimPhase.currency || _pricePerToken != currentClaimPhase.pricePerToken) {
            revert DropSinglePhase__InvalidCurrencyOrPrice(
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
            revert DropSinglePhase__InvalidQuantity();
        }

        if (currentClaimPhase.supplyClaimed + _quantity > currentClaimPhase.maxClaimableSupply) {
            revert DropSinglePhase__ExceedMaxClaimableSupply(
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

        (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp) = _claimTimestamp(_tokenId, _claimer);
        if (
            currentClaimPhase.startTimestamp > block.timestamp ||
            (lastClaimedAt != 0 && block.timestamp < nextValidClaimTimestamp)
        ) {
            revert DropSinglePhase__CannotClaimYet(
                block.timestamp,
                currentClaimPhase.startTimestamp,
                lastClaimedAt,
                nextValidClaimTimestamp
            );
        }
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(address _claimer)
        public
        view
        returns (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp)
    {
        return _claimTimestamp(type(uint256).max, _claimer);
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(uint256 _tokenId, address _claimer)
        public
        view
        returns (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp)
    {
        return _claimTimestamp(_tokenId, _claimer);
    }

    function _claimTimestamp(uint256 _tokenId, address _claimer)
        internal
        view
        returns (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp)
    {
        lastClaimedAt = lastClaimTimestamp[conditionId[_tokenId]][_claimer];

        unchecked {
            nextValidClaimTimestamp = lastClaimedAt + claimCondition[_tokenId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimedAt) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Merkle proof verification
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether a claimer meets the claim condition's allowlist criteria.
    function verifyClaimMerkleProof(
        address _claimer,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        return _verifyClaimMerkleProof(_claimer, type(uint256).max, _quantity, _allowlistProof);
    }

    /// @dev Checks whether a claimer meets the claim condition's allowlist criteria, for a given tokenId
    function verifyClaimMerkleProof(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        return _verifyClaimMerkleProof(_claimer, _tokenId, _quantity, _allowlistProof);
    }

    function _verifyClaimMerkleProof(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        AllowlistProof calldata _allowlistProof
    ) internal view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        ClaimCondition memory currentClaimPhase = claimCondition[_tokenId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _allowlistProof.proof,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _allowlistProof.maxQuantityInAllowlist))
            );
            if (!validMerkleProof) {
                revert DropSinglePhase__NotInWhitelist();
            }

            if (usedAllowlistSpot[conditionId[_tokenId]].get(merkleProofIndex)) {
                revert DropSinglePhase__ProofClaimed();
            }

            if (_allowlistProof.maxQuantityInAllowlist != 0 && _quantity > _allowlistProof.maxQuantityInAllowlist) {
                revert DropSinglePhase__InvalidQuantityProof(_allowlistProof.maxQuantityInAllowlist);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Set/get claim conditions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set claim condition.
    function setClaimConditions(ClaimCondition calldata _condition, bool _resetClaimEligibility)
        external
        virtual
        override
    {
        if (!_canSetClaimConditions()) {
            revert DropSinglePhase__NotAuthorized();
        }

        _setClaimConditions(type(uint256).max, _condition, _resetClaimEligibility);

        emit ClaimConditionUpdated(_condition, _resetClaimEligibility);
    }

    /// @dev Lets a contract admin set claim conditions, for a tokenId.
    function setClaimConditions(
        uint256 _tokenId,
        ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external virtual override {
        if (!_canSetClaimConditions()) {
            revert DropSinglePhase__NotAuthorized();
        }

        // require(_tokenId != type(uint256).max, "invalid token id");

        _setClaimConditions(_tokenId, _condition, _resetClaimEligibility);

        emit ClaimConditionUpdated(_condition, _tokenId, _resetClaimEligibility);
    }

    /// @dev At any given moment, returns the uid for the active claim condition.
    function getActiveClaimConditionId() public view returns (bytes32) {
        return _activeClaimConditionId(type(uint256).max);
    }

    /// @dev At any given moment, returns the uid for the active claim condition, for a given tokenId.
    function getActiveClaimConditionId(uint256 _tokenId) public view returns (bytes32) {
        return _activeClaimConditionId(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set claim conditions.
    function _setClaimConditions(
        uint256 _tokenId,
        ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) internal {
        bytes32 targetConditionId = conditionId[_tokenId];
        uint256 supplyClaimedAlready = claimCondition[_tokenId].supplyClaimed;

        /**
         *  `lastClaimTimestamp` and `usedAllowListSpot` are mappings that use a
         *  claim condition's UID as a key.
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_conditions`, effectively resetting the restrictions on claims expressed
         *  by `lastClaimTimestamp` and `usedAllowListSpot`.
         */

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), _tokenId, block.number));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert DropSinglePhase__MaxSupplyClaimedAlready(supplyClaimedAlready);
        }

        claimCondition[_tokenId] = ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerTransaction: _condition.quantityLimitPerTransaction,
            waitTimeInSecondsBetweenClaims: _condition.waitTimeInSecondsBetweenClaims,
            merkleRoot: _condition.merkleRoot,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency
        });
        conditionId[_tokenId] = targetConditionId;
    }

    /// @dev At any given moment, returns the uid for the active claim condition, for a given tokenId.
    function _activeClaimConditionId(uint256 _tokenId) internal view returns (bytes32) {
        if (conditionId[_tokenId] != 0) return conditionId[_tokenId];

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
    function transferTokensOnClaim(
        address _to,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal virtual returns (uint256 startTokenId);

    /// @dev Determine what wallet can update claim conditions
    function _canSetClaimConditions() internal virtual returns (bool);
}
