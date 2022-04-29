// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../eip/ERC721AUpgradeable.sol";

import "../interfaces/ITWFee.sol";
import "../interfaces/IThirdwebContract.sol";
import "../interfaces/drop/IDropClaimCondition.sol";

import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "../lib/CurrencyTransferLib.sol";
import "../lib/FeeType.sol";

//  ==========  Features    ==========

import "../feature/interface/IThirdwebPlatformFee.sol";
import "../feature/interface/IThirdwebPrimarySale.sol";
import "../feature/interface/IThirdwebRoyalty.sol";
import "../feature/interface/IThirdwebOwnable.sol";
import "../feature/DelayedReveal.sol";
import "../feature/LazyMint.sol";
import "../feature/SignatureMintERC721Upgradeable.sol";

contract SignatureDrop is
    Initializable,
    IThirdwebContract,
    IThirdwebOwnable,
    IThirdwebRoyalty,
    IThirdwebPrimarySale,
    IThirdwebPlatformFee,
    IDropClaimCondition,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    DelayedReveal,
    LazyMint,
    SignatureMintERC721Upgradeable,
    ERC721AUpgradeable
{
    using StringsUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("SignatureDrop");
    uint256 private constant VERSION = 1;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The thirdweb contract with fee related information.
    ITWFee private immutable thirdwebFee;

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev The address that receives all primary sales value.
    address public primarySaleRecipient;

    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;

    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    uint256 public nextTokenIdToMint;

    /// @dev The active conditions for claiming lazy minted tokens.
    ClaimCondition public claimCondition;

    /// @dev The ID for the active claim condition.
    bytes32 private conditionId;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from claimer => condition Id => timestamp of last claim.
    mapping(address => mapping(bytes32 => uint256)) private lastClaimTimestamp;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event TokenLazyMinted(uint256 indexed startId, uint256 amount, string indexed baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 index, string revealedURI);
    event TokensMinted(
        address indexed minter,
        address receiver,
        uint256 indexed startTokenId,
        uint256 amountMinted,
        uint256 pricePerToken,
        address indexed currency
    );
    event ClaimConditionUpdated(ClaimCondition condition, bool resetEligibility);

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _thirdwebFee) initializer {
        thirdwebFee = ITWFee(_thirdwebFee);
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);
        __SignatureMintERC721_init();

        // Initialize this contract's state.
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);
        platformFeeRecipient = _platformFeeRecipient;
        platformFeeBps = uint16(_platformFeeBps);
        primarySaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        _owner = _defaultAdmin;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(getBaseURI(_tokenId), _tokenId.toString()));
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /// @dev Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                    Lazy minting + delayed-reveal logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) external onlyRole(MINTER_ROLE) {
        (bytes memory encryptedBaseURI, uint256 expectedStartId) = abi.decode(_data, (bytes, uint256));

        uint256 startId = nextTokenIdToMint;
        require(startId == expectedStartId, "Unexpected start Id");

        uint256 batchId;
        (nextTokenIdToMint, batchId) = _batchMint(startId, _amount, _baseURIForTokens);

        if (encryptedBaseURI.length != 0) {
            _setEncryptedBaseURI(batchId, encryptedBaseURI);
        }

        emit TokenLazyMinted(startId, _amount, _baseURIForTokens, encryptedBaseURI);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key)
        external
        onlyRole(MINTER_ROLE)
        returns (string memory revealedURI)
    {
        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*///////////////////////////////////////////////////////////////
                    Claiming lazy minted tokens logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Claim lazy minted tokens via signature.
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature) external payable nonReentrant {
        require(_req.quantity > 0, "minting zero tokens");

        uint256 tokenIdToMint = _currentIndex;
        require(tokenIdToMint + _req.quantity <= nextTokenIdToMint, "not enough minted tokens.");

        // Verify and process payload.
        _processRequest(_req, _signature);

        // Get receiver of tokens.
        address receiver = _req.to == address(0) ? msg.sender : _req.to;

        // Collect price
        collectPrice(_req.quantity, _req.currency, _req.pricePerToken);

        // Mint tokens.
        _mint(receiver, _req.quantity);

        emit TokensMinted(_msgSender(), _req.to, tokenIdToMint, _req.quantity, _req.pricePerToken, _req.currency);
    }

    /// @dev Lets an account claim NFTs.
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) external payable {
        ClaimCondition memory condition = claimCondition;

        // Verify claim
        require(
            _currency == condition.currency && _pricePerToken == condition.pricePerToken,
            "invalid currency or price."
        );
        require(_quantity > 0 && _quantity <= condition.quantityLimitPerTransaction, "invalid quantity.");
        require(condition.supplyClaimed + _quantity <= condition.maxClaimableSupply, "exceed max claimable supply.");

        uint256 tokenIdToClaim = _currentIndex;
        require(tokenIdToClaim + _quantity <= nextTokenIdToMint, "not enough minted tokens.");

        uint256 lastClaimTimestampForClaimer = lastClaimTimestamp[msg.sender][conditionId];
        require(
            lastClaimTimestampForClaimer == 0 ||
                block.timestamp >= lastClaimTimestampForClaimer + condition.waitTimeInSecondsBetweenClaims,
            "cannot claim."
        );

        // Collect price for claim.
        collectPrice(_quantity, _currency, _pricePerToken);

        // Mark the claim.
        lastClaimTimestamp[msg.sender][conditionId] = block.timestamp;
        claimCondition.supplyClaimed += _quantity;

        // Transfer tokens being claimed.
        _mint(_receiver, _quantity);

        emit TokensMinted(_msgSender(), _receiver, tokenIdToClaim, _quantity, _pricePerToken, _currency);
    }

    function setClaimCondition(ClaimCondition calldata _condition, bool _resetClaimEligibility)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
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

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPrice(
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

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(MINTER_ROLE, _signer);
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_royaltyBps <= MAX_BPS, "> MAX_BPS");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bps <= MAX_BPS, "> MAX_BPS");

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_platformFeeBps <= MAX_BPS, "> MAX_BPS.");

        platformFeeBps = uint16(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        address ownerOfToken = ownerOf(tokenId);
        //solhint-disable-next-line max-line-length
        require(
            _msgSender() == ownerOfToken
                || isApprovedForAll(ownerOfToken, _msgSender())
                || getApproved(tokenId) == _msgSender(),
            "caller not owner nor approved"
        );
        _burn(tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "!TRANSFER_ROLE");
        }
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
