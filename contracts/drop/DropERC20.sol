// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { IDropERC20 } from "../interfaces/drop/IDropERC20.sol";

// Base
import "../token/TokenERC20.sol";

// Security
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";

// Helper interfaces
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Thirdweb top-level
import "../TWFee.sol";

contract DropERC20 is IDropERC20, ReentrancyGuardUpgradeable, TokenERC20 {
    bytes32 private constant MODULE_TYPE = bytes32("DropERC20");
    uint128 private constant VERSION = 1;

    /// @dev Max basis points in the thirdweb system
    uint128 private constant MAX_BPS = 10_000;

    /// @dev The % of primary sales collected as platform fees.
    uint128 private platformFeeBps;

    /// @dev The address interpreted as native token of the chain.
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The thirdweb contract with fee related information.
    TWFee private immutable thirdwebFee;

    /// @dev The address that receives all primary sales value.
    address public primarySaleRecipient;

    /// @dev The address that receives the platform fees all primary sales value.
    address private platformFeeRecipient;

    /// @dev The claim conditions at any given moment.
    ClaimConditions public claimConditions;

    constructor(address _thirdwebFee) initializer {
        thirdwebFee = TWFee(_thirdwebFee);
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _trustedForwarder,
        address _primarySaleRecipient,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        __TokenERC20_init(_name, _symbol, _trustedForwarder, _contractURI);

        primarySaleRecipient = _primarySaleRecipient;
        platformFeeRecipient = _platformFeeRecipient;
        platformFeeBps = _platformFeeBps;
    }

    //      =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function moduleType() external pure override(IThirdwebModule, TokenERC20) returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function version() external pure override(IThirdwebModule, TokenERC20) returns (uint8) {
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
            require(MerkleProofUpgradeable.verify(_proofs, _claimCondition.merkleRoot, leaf), "not in whitelist.");
        }
    }

    //      =====   External functions  =====

    /// @dev Lets the contract accept ether.
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId, according to claim conditions.
    function claim(
        address _receiver,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) external payable nonReentrant {
        // Get the claim conditions.
        uint256 activeConditionIndex = getIndexOfActiveCondition();
        ClaimCondition memory condition = claimConditions.claimConditionAtIndex[activeConditionIndex];

        // Verify claim validity. If not valid, revert.
        verifyClaim(_msgSender(), _quantity, _proofs, activeConditionIndex);

        // If there's a price, collect price.
        collectClaimPrice(condition, _quantity);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, activeConditionIndex, _quantity);

        emit ClaimedTokens(activeConditionIndex, _msgSender(), _receiver, _quantity);
    }

    /// @dev Lets a module admin set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _conditions, bool _resetRestriction)
        external
        onlyModuleAdmin
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

        emit NewClaimConditions(_conditions);
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _primarySaleRecipient) external onlyModuleAdmin {
        primarySaleRecipient = _primarySaleRecipient;
        emit NewPrimarySaleRecipient(_primarySaleRecipient);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external onlyModuleAdmin {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeUpdates(_platformFeeRecipient, _platformFeeBps);
    }

    //      =====   Getter functions  =====

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

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

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectClaimPrice(ClaimCondition memory _claimCondition, uint256 _quantityToClaim) internal {
        if (_claimCondition.pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _claimCondition.pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
        (address twFeeRecipient, uint256 twFeeBps) = thirdwebFee.getFeeInfo(address(this), TWFee.FeeType.Transaction);
        uint256 twFee = (totalPrice * twFeeBps) / MAX_BPS;

        if (_claimCondition.currency == NATIVE_TOKEN) {
            require(msg.value == totalPrice, "must send total price.");
        }

        CurrencyTransferLib.transferCurrency(
            _claimCondition.currency,
            _msgSender(),
            platformFeeRecipient,
            platformFees
        );
        CurrencyTransferLib.transferCurrency(_claimCondition.currency, _msgSender(), twFeeRecipient, twFee);
        CurrencyTransferLib.transferCurrency(
            _claimCondition.currency,
            _msgSender(),
            primarySaleRecipient,
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
