// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Interface
import { IDropERC20 } from "../interfaces/drop/IDropERC20.sol";

// Token
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

// Security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Meta transactions
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "../lib/MerkleProof.sol";
import "../lib/CurrencyTransferLib.sol";
import "../lib/FeeType.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// Helper interfaces
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Thirdweb top-level
import "../TWFee.sol";

contract DropERC20 is 
    IDropERC20,
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    ERC20VotesUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using BitMaps for BitMaps.BitMap;

    bytes32 private constant MODULE_TYPE = bytes32("DropERC20");
    uint128 private constant VERSION = 1;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev The thirdweb contract with fee related information.
    TWFee internal immutable thirdwebFee;

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    string public contractURI;

    /// @dev Max bps in the thirdweb system
    uint128 internal constant MAX_BPS = 10_000;

    /// @dev The % of primary sales collected by the contract as fees.
    uint128 internal platformFeeBps;

    /// @dev The adress that receives all primary sales value.
    address internal platformFeeRecipient;

    /// @dev The adress that receives all primary sales value.
    address public primarySaleRecipient;

    /// @dev The max number of claim per wallet.
    uint256 public maxWalletClaimCount;

    /// @dev Token max total supply for the collection.
    uint256 public maxTotalSupply;

    /// @dev The claim conditions at any given moment.
    ClaimConditionList public claimCondition;

    /// @dev Mapping from address => number of tokens a wallet has claimed.
    mapping(address => uint256) public walletClaimCount;

    constructor(address _thirdwebFee) initializer {
        thirdwebFee = TWFee(_thirdwebFee);
    }

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
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init_unchained(_trustedForwarder);
        __ERC20Permit_init(_name);
        __ERC20_init_unchained(_name, _symbol);

        contractURI = _contractURI;
        primarySaleRecipient = _primarySaleRecipient;
        platformFeeRecipient = _platformFeeRecipient;
        platformFeeBps = uint128(_platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(PAUSER_ROLE, _defaultAdmin);

        _setupRole(TRANSFER_ROLE, address(0));
    }

    //      =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);

        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }
    }

    /// @dev At any given moment, returns the uid for the active claim condition.
    function getActiveClaimConditionId() public view returns (uint256) {
        for (uint256 i = claimCondition.currentStartId + claimCondition.count; i > claimCondition.currentStartId; i--) {
            if (block.timestamp >= claimCondition.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("no active mint condition.");
    }

    /// @dev Returns the timestamp for next available claim for a claimer address
    function getClaimTimestamp(uint256 _conditionId, address _claimer)
        public
        view
        returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp)
    {
        lastClaimTimestamp = claimCondition.limitLastClaimTimestamp[_conditionId][_claimer];

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimCondition.phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    // /// @dev Checks whether a claimer can claim tokens in a particular claim condition.
    // function verifyClaim(
    //     address _claimer,
    //     uint256 _quantity,
    //     address _currency,
    //     uint256 _pricePerToken,
    //     bytes32[] calldata _proofs,
    //     uint256 _conditionIndex
    // ) public view {
    //     ClaimCondition memory _claimCondition = claimConditions.claimConditionAtIndex[_conditionIndex];

    //     require(
    //         _currency == _claimCondition.currency && _pricePerToken == _claimCondition.pricePerToken,
    //         "invalid currency or price specified."
    //     );
    //     require(
    //         _quantity > 0 && _claimCondition.supplyClaimed + _quantity <= _claimCondition.maxClaimableSupply,
    //         "invalid quantity claimed."
    //     );

    //     uint256 timestampIndex = _conditionIndex + claimConditions.timstampLimitIndex;
    //     uint256 timestampOfLastClaim = claimConditions.timestampOfLastClaim[_claimer][timestampIndex];
    //     uint256 nextValidTimestampForClaim = getTimestampForNextValidClaim(_conditionIndex, _claimer);
    //     require(timestampOfLastClaim == 0 || block.timestamp >= nextValidTimestampForClaim, "cannot claim yet.");

    //     if (_claimCondition.merkleRoot != bytes32(0)) {
    //         bytes32 leaf = keccak256(abi.encodePacked(_claimer, _quantity));
    //         require(MerkleProofUpgradeable.verify(_proofs, _claimCondition.merkleRoot, leaf), "not in whitelist.");
    //     }
    // }

    /// @dev Checks whether a request to claim tokens obeys the active mint condition.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) public view {
        ClaimCondition memory currentClaimPhase = claimCondition.phases[_conditionId];

        require(
            _currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken,
            "invalid currency or price specified."
        );
        require(
            _quantity > 0 && _quantity <= currentClaimPhase.quantityLimitPerTransaction,
            "invalid quantity claimed."
        );
        require(
            currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply,
            "exceed max mint supply."
        );
        
        require(maxTotalSupply == 0 || totalSupply() + _quantity <= maxTotalSupply, "exceed max total supply.");
        require(
            maxWalletClaimCount == 0 || walletClaimCount[_claimer] + _quantity <= maxWalletClaimCount,
            "exceed claim limit for wallet"
        );

        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(_conditionId, _claimer);
        require(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp, "cannot claim yet.");
    }

    function verifyClaimMerkleProof(
        uint256 _conditionId,
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        ClaimCondition memory currentClaimPhase = claimCondition.phases[_conditionId];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );
            require(validMerkleProof, "not in whitelist.");
            require(!claimCondition.limitMerkleProofClaim[_conditionId].get(merkleProofIndex), "proof claimed.");
            require(
                _proofMaxQuantityPerTransaction == 0 || _quantity <= _proofMaxQuantityPerTransaction,
                "invalid quantity proof."
            );
        }
    }

    //      =====   External functions  =====

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId, according to claim conditions.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable nonReentrant {

        // Get the claim conditions.
        uint256 activeConditionId = getActiveClaimConditionId();

        // Verify claim validity. If not valid, revert.
        verifyClaim(activeConditionId, _msgSender(), _quantity, _currency, _pricePerToken);

        (bool validMerkleProof, uint256 merkleProofIndex) = verifyClaimMerkleProof(
            activeConditionId,
            _msgSender(),
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // if the current claim condition and has a merkle root and the provided proof is valid
        // if validMerkleProof is false, it means that claim condition does not have a merkle root
        // if invalid proof is provided, the verifyClaimMerkleProof would fail on require.
        if (validMerkleProof) {
            claimCondition.limitMerkleProofClaim[activeConditionId].set(merkleProofIndex);
        }

        // If there's a price, collect price.
        collectClaimPrice(_quantity, _currency, _pricePerToken);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, activeConditionId, _quantity);

        emit TokensClaimed(activeConditionId, _msgSender(), _receiver, _quantity);
    }

    /// @dev Lets a module admin set claim conditions.
    function setClaimConditions(ClaimCondition[] calldata _phases, bool _resetLimitRestriction)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 existingStartIndex = claimCondition.currentStartId;
        uint256 existingPhaseCount = claimCondition.count;

        // if it's to reset restriction, all new claim phases would start at the end of the existing batch.
        // otherwise, the new claim phases would override the existing phases and limits from the existing start index
        uint256 newStartIndex = existingPhaseCount;
        if (_resetLimitRestriction) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        uint256 lastConditionStartTimestamp;
        for (uint256 i = 0; i < _phases.length; i++) {
            require(
                lastConditionStartTimestamp == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp,
                "startTimestamp must be in ascending order."
            );

            claimCondition.phases[newStartIndex + i] = _phases[i];
            claimCondition.phases[newStartIndex + i].supplyClaimed = 0;

            lastConditionStartTimestamp = _phases[i].startTimestamp;
        }

        // freeing up claim phases and claim limit
        // if we are resetting restriction, then we'd clean up previous batch maps
        // if we are not, then we'd only clean up unused claim phases and limits.
        if (_resetLimitRestriction) {
            for (uint256 i = 0; i < existingPhaseCount; i++) {
                delete claimCondition.phases[existingStartIndex + i];
                delete claimCondition.limitMerkleProofClaim[existingStartIndex + i];
                // can't delete limitLastClaimTimestamp because we don't have addresses
            }
        } else {
            // if there are more old (existing) phases than the newly set ones, delete all the remaining
            // unused phases and limits
            // if there are more new phases than old phases, then we'd only need to set the `length` properly
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete claimCondition.phases[newStartIndex + i];
                    delete claimCondition.limitMerkleProofClaim[newStartIndex + i];
                    // can't delete limitLastClaimTimestamp because we don't have addresses
                }
            }
        }

        claimCondition.count = _phases.length;
        claimCondition.currentStartId = newStartIndex;

        emit ClaimConditionsUpdated(_phases);
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set a claim limit on a wallet.
    function setWalletClaimCount(address _claimer, uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        walletClaimCount[_claimer] = _count;
        emit WalletClaimCountUpdated(_claimer, _count);
    }

    /// @dev Lets a module admin set a maximum number of claim per wallet.
    function setMaxWalletClaimCount(uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxWalletClaimCount = _count;
        emit MaxWalletClaimCountUpdated(_count);
    }

    /// @dev Lets a module admin set the maximum number of supply for the collection.
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
    }

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    //      =====   Internal functions  =====

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectClaimPrice(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
        (address twFeeRecipient, uint256 twFeeBps) = thirdwebFee.getFeeInfo(address(this), FeeType.PRIMARY_SALE);
        uint256 twFee = (totalPrice * twFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == totalPrice, "must send total price.");
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), twFeeRecipient, twFee);
        CurrencyTransferLib.transferCurrency(
            _currency,
            _msgSender(),
            primarySaleRecipient,
            totalPrice - platformFees - twFee
        );
    }

    /// @dev Transfers the tokens being claimed.
    function transferClaimedTokens(
        address _to,
        uint256 _conditionId,
        uint256 _quantityBeingClaimed
    ) internal {
        // Update the supply minted under mint condition.
        claimCondition.phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when to != msg.sender, it'd use msg.sender's limits.
        // behavior would be similar to msg.sender mint for itself, then transfer to `to`.
        claimCondition.limitLastClaimTimestamp[_conditionId][_msgSender()] = block.timestamp;

        // wallet count limit is global, not scoped to the phases
        walletClaimCount[_msgSender()] += _quantityBeingClaimed;

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

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
