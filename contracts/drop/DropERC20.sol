// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Interface
import { IDropERC20 } from "../interfaces/drop/IDropERC20.sol";

// Base
import "../token/TokenERC20.sol";

// Security
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";
import "../lib/FeeType.sol";

// Helper interfaces
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Thirdweb top-level
import "../TWFee.sol";

contract DropERC20 is Initializable, IDropERC20, ReentrancyGuardUpgradeable, TokenERC20 {
    bytes32 private constant MODULE_TYPE = bytes32("DropERC20");
    uint128 private constant VERSION = 1;

    /// @dev The claim conditions at any given moment.
    ClaimConditions public claimConditions;

    constructor(address _thirdwebFee) TokenERC20(_thirdwebFee) initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _trustedForwarder,
        address _primarySaleRecipient,
        uint256 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        __TokenERC20_init(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarder,
            _primarySaleRecipient,
            _platformFeeRecipient,
            _platformFeeBps
        );
    }

    //      =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function contractType() external pure override(IThirdwebContract, TokenERC20) returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure override(IThirdwebContract, TokenERC20) returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev At any given moment, returns the uid for the active claim condition.
    function getIndexOfActiveCondition() public view returns (uint256) {
        uint256 totalConditionCount = claimConditions.totalConditionCount;

        for (uint256 i = totalConditionCount; i > 0; i -= 1) {
            if (block.timestamp >= claimConditions.claimConditionAtIndex[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("no active mint condition.");
    }

    /// @dev Checks whether a claimer can claim tokens in a particular claim condition.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _conditionIndex
    ) public view {
        ClaimCondition memory _claimCondition = claimConditions.claimConditionAtIndex[_conditionIndex];

        require(
            _currency == _claimCondition.currency && _pricePerToken == _claimCondition.pricePerToken,
            "invalid currency or price specified."
        );
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
            require(MerkleProofUpgradeable.verify(_proofs, _claimCondition.merkleRoot, leaf), "not in whitelist.");
        }
    }

    //      =====   External functions  =====

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId, according to claim conditions.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs
    ) external payable nonReentrant {
        // Get the claim conditions.
        uint256 activeConditionIndex = getIndexOfActiveCondition();

        // Verify claim validity. If not valid, revert.
        verifyClaim(_msgSender(), _quantity, _currency, _pricePerToken, _proofs, activeConditionIndex);

        // If there's a price, collect price.
        collectPrice(primarySaleRecipient, _currency, _pricePerToken);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, activeConditionIndex, _quantity);

        emit TokensClaimed(activeConditionIndex, _msgSender(), _receiver, _quantity);
    }

    /// @dev Lets a module admin set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _conditions, bool _resetRestriction)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 lastConditionStartTimestamp;
        uint256 indexForCondition;

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

        if (_resetRestriction) {
            claimConditions.timstampLimitIndex += indexForCondition;
        }

        emit ClaimConditionsUpdated(_conditions);
    }

    //      =====   Getter functions  =====

    /// @dev Returns the next calid timestamp for claiming, for a given claimer and claim condition index.
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

    /// @dev Returns the  claim conditions at the given index.
    function getClaimConditionAtIndex(uint256 _index) external view returns (ClaimCondition memory mintCondition) {
        mintCondition = claimConditions.claimConditionAtIndex[_index];
    }

    //      =====   Internal functions  =====

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

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
