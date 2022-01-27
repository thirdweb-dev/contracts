// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { IDropERC721 } from "../interfaces/drop/IDropERC721.sol";

// Token
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

// Access Control + security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Meta transactions
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "../openzeppelin-presets/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";

// Helper interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Thirdweb top-level
import "../TWFee.sol";

contract DropERC721 is
    Initializable,
    IDropERC721,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable
{
    using StringsUpgradeable for uint256;

    bytes32 private constant MODULE_TYPE = bytes32("DropERC721");
    uint256 private constant VERSION = 1;

    /// @dev Only TRANSFER_ROLE holders can participate in transfers, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Max bps in the thirdweb system
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The address interpreted as native token of the chain.
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The thirdweb contract with fee related information.
    TWFee public immutable thirdwebFees;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 public nextTokenIdToMint;

    /// @dev The next token ID of the NFT that can be claimed.
    uint256 public nextTokenIdToClaim;

    /// @dev The adress that receives all primary sales value.
    address public primarySaleRecipient;

    /// @dev The adress that receives all primary sales value.
    address private platformFeeRecipient;

    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint128 private royaltyBps;

    /// @dev The % of primary sales collected by the contract as fees.
    uint128 private platformFeeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public isTransferRestricted;

    /// @dev Contract level metadata.
    string public contractURI;

    uint256[] private baseURIIndices;

    /// @dev Mapping from 'end token Id' => URI that overrides `baseURI + tokenId` convention.
    mapping(uint256 => string) private baseURI;

    /// @dev The claim conditions at any given moment.
    ClaimConditions public claimConditions;

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    /// @dev Checks whether caller has MINTER_ROLE.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _;
    }

    constructor(address _thirdwebFees) initializer {
        thirdwebFees = TWFee(_thirdwebFees);
    }

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
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarder);
        __ERC721_init(_name, _symbol);

        // Initialize this contract's state.
        royaltyRecipient = _royaltyReceiver;
        royaltyBps = _royaltyBps;
        platformFeeRecipient = _platformFeeRecipient;
        primarySaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        platformFeeBps = _platformFeeBps;

        address deployer = _msgSender();
        _owner = deployer;
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINTER_ROLE, deployer);
        _setupRole(TRANSFER_ROLE, deployer);
    }

    ///     =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function moduleType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function version() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        for (uint256 i = 0; i < baseURIIndices.length; i += 1) {
            if (_tokenId < baseURIIndices[i]) {
                return string(abi.encodePacked(baseURI[baseURIIndices[i]], _tokenId.toString()));
            }
        }

        return "";
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

    /// @dev Checks whether a request to claim tokens obeys the active mint condition.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _conditionIndex
    ) public view {
        ClaimCondition memory _claimCondition = claimConditions.claimConditionAtIndex[_conditionIndex];

        require(_quantity > 0 && _quantity <= _claimCondition.quantityLimitPerTransaction, "invalid quantity claimed.");
        require(
            _claimCondition.supplyClaimed + _quantity <= _claimCondition.maxClaimableSupply,
            "exceed max mint supply."
        );
        require(nextTokenIdToClaim + _quantity <= nextTokenIdToMint, "not enough minted tokens.");

        uint256 timestampIndex = _conditionIndex + claimConditions.timstampLimitIndex;
        uint256 timestampOfLastClaim = claimConditions.timestampOfLastClaim[_claimer][timestampIndex];
        uint256 nextValidTimestampForClaim = getTimestampForNextValidClaim(_conditionIndex, _claimer);
        require(timestampOfLastClaim == 0 || block.timestamp >= nextValidTimestampForClaim, "cannot claim yet.");

        if (_claimCondition.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(_claimer));
            require(MerkleProofUpgradeable.verify(_proofs, _claimCondition.merkleRoot, leaf), "not in whitelist.");
        }
    }

    ///     =====   External functions  =====

    /// @dev Distributes accrued royalty and thirdweb fees to the relevant stakeholders.
    function withdrawFunds(address _currency) external {
        address recipient = royaltyRecipient;
        (address twFeeRecipient, uint256 twFeeBps) = thirdwebFees.getFeeInfo(address(this), TWFee.FeeType.Royalty);

        uint256 totalTransferAmount = _currency == NATIVE_TOKEN
            ? address(this).balance
            : IERC20(_currency).balanceOf(_currency);
        uint256 fees = (totalTransferAmount * twFeeBps) / MAX_BPS;

        CurrencyTransferLib.transferCurrency(_currency, address(this), recipient, totalTransferAmount - fees);
        CurrencyTransferLib.transferCurrency(_currency, address(this), twFeeRecipient, fees);

        emit FundsWithdrawn(recipient, twFeeRecipient, totalTransferAmount, fees);
    }

    /// @dev Lets the contract accept ether.
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @dev See EIP-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        (, uint256 royaltyFeeBps) = thirdwebFees.getFeeInfo(address(this), TWFee.FeeType.Transaction);
        if (royaltyBps > 0) {
            royaltyAmount = (salePrice * (royaltyBps + royaltyFeeBps)) / MAX_BPS;
        }
    }

    /**
     *  @dev Lets an account with `MINTER_ROLE` mint tokens of ID from `nextTokenIdToMint`
     *       to `nextTokenIdToMint + _amount - 1`. The URIs for these tokenIds is baseURI + `${tokenId}`.
     */
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external onlyMinter {
        uint256 startId = nextTokenIdToMint;
        uint256 baseURIIndex = startId + _amount;

        nextTokenIdToMint = baseURIIndex;
        baseURI[baseURIIndex] = _baseURIForTokens;
        baseURIIndices.push(baseURIIndex);

        emit LazyMintedTokens(startId, startId + _amount - 1, _baseURIForTokens);
    }

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId, according to claim conditions.
    function claim(
        address _receiver,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) external payable nonReentrant {
        uint256 tokenIdToClaim = nextTokenIdToClaim;

        // Get the claim conditions.
        uint256 activeConditionIndex = getIndexOfActiveCondition();
        ClaimCondition memory condition = claimConditions.claimConditionAtIndex[activeConditionIndex];

        // Verify claim validity. If not valid, revert.
        verifyClaim(_msgSender(), _quantity, _proofs, activeConditionIndex);

        // If there's a price, collect price.
        collectClaimPrice(condition, _quantity);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, activeConditionIndex, _quantity);

        emit ClaimedTokens(activeConditionIndex, _msgSender(), _receiver, tokenIdToClaim, _quantity);
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
            require(_conditions[i].quantityLimitPerTransaction > 0, "quantity limit cannot be 0.");

            claimConditions.claimConditionAtIndex[indexForCondition] = ClaimCondition({
                startTimestamp: _conditions[i].startTimestamp,
                maxClaimableSupply: _conditions[i].maxClaimableSupply,
                supplyClaimed: 0,
                quantityLimitPerTransaction: _conditions[i].quantityLimitPerTransaction,
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
    function setPrimarySaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        primarySaleRecipient = _saleRecipient;
        emit NewPrimarySaleRecipient(_saleRecipient);
    }

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "exceed royalty bps");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);

        emit RoyaltyUpdated(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external onlyModuleAdmin {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeUpdates(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        isTransferRestricted = _restrictedTransfer;

        emit TransfersRestricted(_restrictedTransfer);
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyModuleAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit NewOwner(_prevOwner, _newOwner);
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyModuleAdmin {
        contractURI = _uri;
    }

    //      =====   Getter functions  =====

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /// @dev Returns the platform fee bps and recipient.
    function getRoyaltyFeeInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

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

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectClaimPrice(ClaimCondition memory _claimCondition, uint256 _quantityToClaim) internal {
        if (_claimCondition.pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _claimCondition.pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
        (address twFeeRecipient, uint256 twFeeBps) = thirdwebFees.getFeeInfo(address(this), TWFee.FeeType.Transaction);
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

        uint256 tokenIdToClaim = nextTokenIdToClaim;

        for (uint256 i = 0; i < _quantityBeingClaimed; i += 1) {
            _mint(_to, tokenIdToClaim);
            tokenIdToClaim += 1;
        }

        nextTokenIdToClaim = tokenIdToClaim;
    }

    ///     =====   ERC 721 functions  =====

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (isTransferRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders");
        }
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
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
