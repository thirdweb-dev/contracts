// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ILazyMintERC721 } from "./ILazyMintERC721.sol";

// Token
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../thirdweb-presets/TWModule.sol";

contract LazyMintERC721 is
    Initializable,
    ILazyMintERC721,
    TWModule,
    ERC721EnumerableUpgradeable
{
    using StringsUpgradeable for uint256;

    bytes32 private constant MODULE_TYPE = "Drop";
    uint256 private constant VERSION = 1;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs (i.e. can call functions prefixed with `lazyMint`).
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The adress that receives all platform fee value.
    address public defaultPlatformFeeRecipient;

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 public nextTokenIdToMint;

    /// @dev The next token ID of the NFT that can be claimed.
    uint256 public nextTokenIdToClaim;

    /// @dev The % of primary sales collected by the contract as fees.
    uint256 public platformFeeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    uint256[] private baseURIIndices;

    /// @dev End token Id => URI that overrides `baseURI + tokenId` convention.
    mapping(uint256 => string) private baseURI;

    /// @dev The claim conditions at any given moment.
    ClaimConditions public claimConditions;

    /// @dev Checks whether caller has MINTER_ROLE.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _;
    }

    constructor(address _nativeTokenWrapper, address _thirdwebFees)
        TWModule(_nativeTokenWrapper, _thirdwebFees)
    {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _trustedForwarder,
        address _platformFeeRecipient,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __TWModule_init(_contractURI, _trustedForwarder, _royaltyRecipient, _royaltyBps);
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        // Initialize this contract's state.
        defaultSaleRecipient = _saleRecipient;
        defaultPlatformFeeRecipient = _platformFeeRecipient;
        platformFeeBps = uint120(_platformFeeBps);

        address deployer = _msgSender();
        _setupRole(MINTER_ROLE, deployer);
        _setupRole(TRANSFER_ROLE, deployer);
    }

    ///     =====   Public functions  =====
    
    /// @dev Returns the module type of the contract.
    function moduleType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function version() external pure returns (uint256) {
        return VERSION;
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

    ///     =====   External functions  =====

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

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId.
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
        verifyClaim(_receiver, _quantity, _proofs, activeConditionIndex);

        // If there's a price, collect price.
        collectClaimPrice(condition, _quantity);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, activeConditionIndex, _quantity);

        emit ClaimedTokens(activeConditionIndex, _msgSender(), _receiver, tokenIdToClaim, _quantity);
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

        require(_quantity > 0 && _quantity <= _claimCondition.quantityLimitPerTransaction, "invalid quantity claimed.");
        require(
            _claimCondition.supplyClaimed + _quantity <= _claimCondition.maxClaimableSupply,
            "exceed max mint supply."
        );

        uint256 timestampIndex = _conditionIndex + claimConditions.timstampLimitIndex;
        uint256 timestampOfLastClaim = claimConditions.timestampOfLastClaim[_claimer][timestampIndex];
        uint256 nextValidTimestampForClaim = getTimestampForNextValidClaim(_conditionIndex, _claimer);
        require(timestampOfLastClaim == 0 || block.timestamp >= nextValidTimestampForClaim, "cannot claim yet.");

        if (_claimCondition.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(_claimer));
            require(MerkleProofUpgradeable.verify(_proofs, _claimCondition.merkleRoot, leaf), "not in whitelist.");
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
        transferCurrency(_claimCondition.currency, _msgSender(), thirdwebFees.getSalesFeeRecipient(address(this)), twFee);
        transferCurrency(_claimCondition.currency, _msgSender(), defaultSaleRecipient, totalPrice - platformFees - twFee);
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

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient);
    }

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPlatformFeeRecipient(address _platformFeeRecipient) external onlyModuleAdmin {
        defaultPlatformFeeRecipient = _platformFeeRecipient;
        emit NewPlatformFeeRecipient(_platformFeeRecipient);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeBps(uint256 _platformFeeBps) external onlyModuleAdmin {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint120(_platformFeeBps);

        emit PrimarySalesFeeUpdates(_platformFeeBps);
    }

    /**
     * @dev For setting NFT royalty recipient.
     *
     * @param _royaltyRecipient The address of which the payments goes to.
     */
    function setRoyaltyRecipient(address _royaltyRecipient) external onlyModuleAdmin {
        _setRoyaltyRecipient(_royaltyRecipient);
    }

    /**
     * @dev For setting royalty basis points.
     *
     * @param _royaltyBps the basis points of royalty. 10_000 = 100%.
     */
    function setRoyaltyBps(uint256 _royaltyBps) external onlyModuleAdmin {
        _setRoyaltyBps(_royaltyBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

        emit TransfersRestricted(_restrictedTransfer);
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
        if (transfersRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, TWModule)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId);  
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, TWModule)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, TWModule)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
