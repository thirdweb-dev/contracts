// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ILazyMintERC20 } from "./ILazyMintERC20.sol";

// Base
import "../../Coin.sol";

// Access Control + security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Utils
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../royalty/TWPayments.sol";

contract LazyMintERC20 is ILazyMintERC20, ReentrancyGuardUpgradeable, TWPayments, Coin {
    bytes32 private constant MODULE_TYPE = keccak256("TOKEN_DROP");
    uint256 private constant VERSION = 1;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The adress that receives all primary sales value.
    address public defaultPlatformFeeRecipient;

    /// @dev The % of primary sales collected by the contract as fees.
    uint128 public platformFeeBps;

    /// @dev The claim conditions at any given moment.
    ClaimConditions public claimConditions;

    constructor(address _nativeTokenWrapper, address _thirdwebFees) TWPayments(_nativeTokenWrapper, _thirdwebFees) {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _trustedForwarder,
        address _saleRecipient,
        address _royaltyReceiver,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        __Coin_init(_name, _symbol, _trustedForwarder, _contractURI);

        __TWPayments_init(_royaltyReceiver, _royaltyBps);

        defaultSaleRecipient = _saleRecipient;
        defaultPlatformFeeRecipient = _platformFeeRecipient;
        platformFeeBps = _platformFeeBps;
    }

    //      =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function moduleType() external pure override returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function version() external pure override returns (uint256) {
        return VERSION;
    }

    /// @dev At any given moment, returns the uid for the active claim condition.
    function getIndexOfActiveCondition() public view returns (uint256) {
        uint256 totalConditionCount = claimConditions.totalConditionCount;

        require(totalConditionCount > 0, "no public mint condition.");

        for (uint256 i = totalConditionCount; i > 0; i -= 1) {
            if (block.timestamp >= claimConditions.claimConditionAtIndex[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("no active mint condition.");
    }

    //      =====   External functions  =====

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId.
    function claim(
        address _receiver,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) external payable nonReentrant {
        // Get the claim conditions.
        uint256 activeConditionIndex = getIndexOfActiveCondition();
        ClaimCondition memory condition = claimConditions.claimConditionAtIndex[activeConditionIndex];

        // Verify claim validity. If not valid, revert.
        verifyClaim(_receiver, _quantity, _proofs, activeConditionIndex);

        // If there's a price, collect price.
        collectClaimPrice(condition, _quantity);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, activeConditionIndex, _quantity);

        emit ClaimedTokens(activeConditionIndex, _msgSender(), _receiver, _quantity);
    }

    /// @dev Lets a module admin update mint conditions without resetting the restrictions.
    function updateClaimConditions(ClaimCondition[] calldata _conditions) external onlyModuleAdmin {
        resetClaimConditions(_conditions);

        emit NewClaimConditions(_conditions);
    }

    /// @dev Lets a module admin set mint conditions.
    function setClaimConditions(ClaimCondition[] calldata _conditions) external onlyModuleAdmin {
        uint256 numOfConditionsSet = resetClaimConditions(_conditions);
        resetTimestampRestriction(numOfConditionsSet);

        emit NewClaimConditions(_conditions);
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient);
    }

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyBps(uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "bps <= 10000.");

        royaltyBps = uint64(_royaltyBps);

        emit RoyaltyUpdated(royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setFeeBps(uint256 _platformFeeBps) public onlyModuleAdmin {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint64(_platformFeeBps);

        emit PrimarySalesFeeUpdates(_platformFeeBps);
    }

    //      =====   Getter functions  =====

    /// @dev Returns the current active mint condition for a given tokenId.
    function getTimestampForNextValidClaim(uint256 _index, address _claimer)
        public
        view
        returns (uint256 nextValidTimestampForClaim)
    {
        uint256 timestampIndex = _index + claimConditions.timstampLimitIndex;
        uint256 timestampOfLastClaim = claimConditions.timestampOfLastClaim[_claimer][timestampIndex];

        unchecked {
            nextValidTimestampForClaim =
                timestampOfLastClaim +
                claimConditions.claimConditionAtIndex[_index].waitTimeInSecondsBetweenClaims;

            if (nextValidTimestampForClaim < timestampOfLastClaim) {
                nextValidTimestampForClaim = type(uint256).max;
            }
        }
    }

    /// @dev Returns the  mint condition for a given tokenId, at the given index.
    function getClaimConditionAtIndex(uint256 _index) external view returns (ClaimCondition memory mintCondition) {
        mintCondition = claimConditions.claimConditionAtIndex[_index];
    }

    //      =====   Internal functions  =====

    /// @dev Overwrites the current claim conditions with new claim conditions
    function resetClaimConditions(ClaimCondition[] calldata _conditions) internal returns (uint256 indexForCondition) {
        // make sure the conditions are sorted in ascending order
        uint256 lastConditionStartTimestamp;

        for (uint256 i = 0; i < _conditions.length; i++) {
            require(
                lastConditionStartTimestamp == 0 || lastConditionStartTimestamp < _conditions[i].startTimestamp,
                "startTimestamp must be in ascending order."
            );
            require(_conditions[i].maxClaimableSupply > 0, "max mint supply cannot be 0.");

            claimConditions.claimConditionAtIndex[indexForCondition] = ClaimCondition({
                startTimestamp: _conditions[i].startTimestamp,
                maxClaimableSupply: _conditions[i].maxClaimableSupply,
                supplyClaimed: 0,
                waitTimeInSecondsBetweenClaims: _conditions[i].waitTimeInSecondsBetweenClaims,
                pricePerToken: _conditions[i].pricePerToken,
                currency: _conditions[i].currency,
                merkleRoot: _conditions[i].merkleRoot
            });

            indexForCondition += 1;
            lastConditionStartTimestamp = _conditions[i].startTimestamp;
        }

        uint256 totalConditionCount = claimConditions.totalConditionCount;
        if (indexForCondition < totalConditionCount) {
            for (uint256 j = indexForCondition; j < totalConditionCount; j += 1) {
                delete claimConditions.claimConditionAtIndex[j];
            }
        }

        claimConditions.totalConditionCount = indexForCondition;
    }

    /// @dev Updates the `timstampLimitIndex` to reset the time restriction between claims, for a claim condition.
    function resetTimestampRestriction(uint256 _factor) internal {
        claimConditions.timstampLimitIndex += _factor;
    }

    /// @dev Checks whether a request to claim tokens obeys the active mint condition.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _conditionIndex
    ) public view {
        ClaimCondition memory _claimCondition = claimConditions.claimConditionAtIndex[_conditionIndex];

        require(
            _quantity > 0 && _claimCondition.supplyClaimed + _quantity <= _claimCondition.maxClaimableSupply,
            "invalid quantity claimed."
        );

        uint256 timestampIndex = _conditionIndex + claimConditions.timstampLimitIndex;
        uint256 timestampOfLastClaim = claimConditions.timestampOfLastClaim[_claimer][timestampIndex];
        uint256 nextValidTimestampForClaim = getTimestampForNextValidClaim(_conditionIndex, _claimer);
        require(timestampOfLastClaim == 0 || block.timestamp >= nextValidTimestampForClaim, "cannot claim yet.");

        if (_claimCondition.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(_claimer, _quantity));
            require(MerkleProof.verify(_proofs, _claimCondition.merkleRoot, leaf), "not in whitelist.");
        }
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectClaimPrice(ClaimCondition memory _claimCondition, uint256 _quantityToClaim) internal {
        if (_claimCondition.pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _claimCondition.pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
        uint256 twFee = (totalPrice * thirdwebFees.getSalesFeeBps(address(this))) / MAX_BPS;

        if (_claimCondition.currency == NATIVE_TOKEN) {
            require(msg.value == totalPrice, "must send total price.");
        }

        transferCurrency(_claimCondition.currency, _msgSender(), defaultPlatformFeeRecipient, platformFees);
        transferCurrency(
            _claimCondition.currency,
            _msgSender(),
            thirdwebFees.getSalesFeeRecipient(address(this)),
            twFee
        );
        transferCurrency(
            _claimCondition.currency,
            _msgSender(),
            defaultSaleRecipient,
            totalPrice - platformFees - twFee
        );
    }

    /// @dev Transfers the tokens being claimed.
    function transferClaimedTokens(
        address _to,
        uint256 _claimConditionIndex,
        uint256 _quantityBeingClaimed
    ) internal {
        // Update the supply minted under mint condition.
        claimConditions.claimConditionAtIndex[_claimConditionIndex].supplyClaimed += _quantityBeingClaimed;
        // Update the claimer's next valid timestamp to mint. If next mint timestamp overflows, cap it to max uint256.
        uint256 timestampIndex = _claimConditionIndex + claimConditions.timstampLimitIndex;
        claimConditions.timestampOfLastClaim[_msgSender()][timestampIndex] = block.timestamp;

        _mint(_to, _quantityBeingClaimed);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, TWPayments)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

