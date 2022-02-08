// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Base
import "./openzeppelin-presets/ERC1155PresetUpgradeable.sol";
import "./openzeppelin-presets/ERC1155PresetUpgradeable.sol";
import "./interfaces/IThirdwebModule.sol";
import "./interfaces/IThirdwebRoyalty.sol";
import "./interfaces/IThirdwebOwnable.sol";

// Token interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

// Meta transactions
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "./openzeppelin-presets/utils/MulticallUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";

// Helper Interfaces
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Thirdweb top-level
import "./TWFee.sol";

contract Bundle is
    IERC2981,
    IThirdwebModule,
    IThirdwebOwnable,
    IThirdwebRoyalty,
    Initializable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC1155PresetUpgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("Bundle");
    uint256 private constant VERSION = 1;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Max bps in the thirdweb system
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The address interpreted as native token of the chain.
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The thirdweb contract with fee related information.
    TWFee public immutable thirdwebFee;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The token Id of the next token to be minted.
    uint256 public nextTokenId;

    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint256 private royaltyBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public isTransferRestricted;

    /// @dev Collection level metadata.
    string public contractURI;

    /// @dev Whether the ERC 1155 token is a wrapped ERC 20 / 721 token.
    enum UnderlyingType {
        None,
        ERC20,
        ERC721
    }

    /// @dev The state of a token.
    struct TokenState {
        address creator;
        string uri;
        UnderlyingType underlyingType;
    }

    /// @dev The state of the underlying ERC 721 token, if any.
    struct ERC721Wrapped {
        address source;
        uint256 tokenId;
    }

    /// @dev The state of the underlying ERC 20 token, if any.
    struct ERC20Wrapped {
        address source;
        uint256 shares;
        uint256 underlyingTokenAmount;
    }

    /// @dev Emitted when restrictions on transfers is updated.
    event RestrictedTransferUpdated(bool transferable);

    /// @dev Emitted when native ERC 1155 tokens are created.
    event NativeTokens(address indexed creator, uint256[] tokenIds, string[] tokenURIs, uint256[] tokenSupplies);

    /// @dev Emitted when ERC 721 wrapped as an ERC 1155 token is minted.
    event ERC721WrappedToken(
        address indexed creator,
        address indexed sourceOfUnderlying,
        uint256 tokenIdOfUnderlying,
        uint256 tokenId,
        string tokenURI
    );

    /// @dev Emitted when an underlying ERC 721 token is redeemed.
    event ERC721Redeemed(
        address indexed redeemer,
        address indexed sourceOfUnderlying,
        uint256 tokenIdOfUnderlying,
        uint256 tokenId
    );

    /// @dev Emitted when ERC 20 wrapped as an ERC 1155 token is minted.
    event ERC20WrappedToken(
        address indexed creator,
        address indexed sourceOfUnderlying,
        uint256 totalAmountOfUnderlying,
        uint256 shares,
        uint256 tokenId,
        string tokenURI
    );

    /// @dev Emitted when an underlying ERC 20 token is redeemed.
    event ERC20Redeemed(
        address indexed redeemer,
        uint256 indexed tokenId,
        address indexed sourceOfUnderlying,
        uint256 tokenAmountReceived,
        uint256 sharesRedeemed
    );

    /// @dev Emitted when a new Owner is set.
    event NewOwner(address prevOwner, address newOwner);

    /// @dev Emitted when royalty info is updated.
    event RoyaltyUpdated(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when the contract receives ether.
    event EtherReceived(address sender, uint256 amount);

    /// @dev Emitted when accrued royalties are withdrawn from the contract.
    event FundsWithdrawn(
        address indexed paymentReceiver,
        address feeRecipient,
        uint256 totalAmount,
        uint256 feeCollected
    );

    /// @dev NFT tokenId => token state.
    mapping(uint256 => TokenState) public tokenState;

    /// @dev NFT tokenId => state of underlying ERC721 token.
    mapping(uint256 => ERC721Wrapped) public erc721WrappedTokens;

    /// @dev NFT tokenId => state of underlying ERC20 token.
    mapping(uint256 => ERC20Wrapped) public erc20WrappedTokens;

    /// @dev Checks whether the caller is a module admin.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin.");
        _;
    }

    /// @dev Checks whether the caller has MINTER_ROLE.
    modifier onlyMinterRole() {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _;
    }

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
        address _royaltyReceiver,
        uint256 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarder);
        __ERC1155Preset_init(_defaultAdmin, _contractURI);

        // Initialize this contract's state.
        name = _name;
        symbol = _symbol;
        royaltyBps = _royaltyBps;
        royaltyRecipient = _royaltyReceiver;
        contractURI = _contractURI;

        _owner = _defaultAdmin;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
    }

    /**
     *      Public functions
     */

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
    function owner() external view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @notice Create native ERC 1155 NFTs.
    function createNativeTokens(
        address to,
        string[] calldata _nftURIs,
        uint256[] calldata _nftSupplies,
        bytes memory data
    ) public whenNotPaused onlyMinterRole returns (uint256[] memory nftIds) {
        require(_nftURIs.length == _nftSupplies.length, "unequal lengths of configs.");
        require(_nftURIs.length > 0, "cannot mint 0 NFTs.");

        // Get creator
        address tokenCreator = _msgSender();

        // Get tokenIds.
        nftIds = new uint256[](_nftURIs.length);

        // Store token state for each token.
        uint256 id = nextTokenId;

        for (uint256 i = 0; i < _nftURIs.length; i++) {
            nftIds[i] = id;

            tokenState[id] = TokenState({
                creator: tokenCreator,
                uri: _nftURIs[i],
                underlyingType: UnderlyingType.None
            });

            id += 1;
        }

        // Update contract level tokenId.
        nextTokenId = id;

        // Mint NFTs to token creator.
        _mintBatch(to, nftIds, _nftSupplies, data);

        emit NativeTokens(tokenCreator, nftIds, _nftURIs, _nftSupplies);
    }

    /// @dev See {ERC1155Minter}.
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(id < nextTokenId, "cannot mint new NFTs.");
        require(tokenState[id].underlyingType == UnderlyingType.None, "cannot freely mint more ERC20 or ERC721.");

        super.mint(to, id, amount, data);
    }

    /// @dev See {ERC1155Minter}.
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        bool validIds = true;
        bool validTokenType = true;

        for (uint256 i = 0; i < ids.length; ++i) {
            if (ids[i] >= nextTokenId && validIds) {
                validIds = false;
            }

            if (tokenState[ids[i]].underlyingType != UnderlyingType.None && validTokenType) {
                validTokenType = false;
            }
        }

        require(validIds, "cannot mint new NFTs.");
        require(validTokenType, "cannot freely mint more ERC20 or ERC721.");

        super.mintBatch(to, ids, amounts, data);
    }

    /**
     *      External functions
     */

    /// @dev Distributes accrued royalty and thirdweb fees to the relevant stakeholders.
    function withdrawFunds(address _currency) external {
        address recipient = royaltyRecipient;
        (address twFeeRecipient, uint256 twFeeBps) = thirdwebFee.getFeeInfo(address(this), TWFee.FeeType.Royalty);

        uint256 totalTransferAmount = _currency == NATIVE_TOKEN
            ? address(this).balance
            : IERC20(_currency).balanceOf(_currency);
        uint256 fees = (totalTransferAmount * twFeeBps) / MAX_BPS;

        CurrencyTransferLib.transferCurrency(_currency, address(this), recipient, totalTransferAmount - fees);
        CurrencyTransferLib.transferCurrency(_currency, address(this), twFeeRecipient, fees);

        emit FundsWithdrawn(recipient, twFeeRecipient, totalTransferAmount, fees);
    }

    /// @dev See EIP-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        (, uint256 royaltyFeeBps) = thirdwebFee.getFeeInfo(address(this), TWFee.FeeType.Transaction);
        if (royaltyBps > 0) {
            royaltyAmount = (salePrice * (royaltyBps + royaltyFeeBps)) / MAX_BPS;
        }
    }

    /// @dev Wraps an ERC721 NFT as an ERC1155 NFT.
    function wrapERC721(
        address _nftContract,
        uint256 _tokenId,
        string calldata _nftURI
    ) external whenNotPaused onlyMinterRole {
        require(IERC721(_nftContract).ownerOf(_tokenId) == _msgSender(), "not owner.");
        require(
            IERC721(_nftContract).getApproved(_tokenId) == address(this) ||
                IERC721(_nftContract).isApprovedForAll(_msgSender(), address(this)),
            "must approve transfer."
        );

        // Get token creator
        address tokenCreator = _msgSender();

        // Get tokenId
        uint256 id = nextTokenId;
        nextTokenId += 1;

        // Transfer the NFT to this contract.
        IERC721(_nftContract).safeTransferFrom(tokenCreator, address(this), _tokenId);

        // Mint wrapped NFT to token creator.
        _mint(tokenCreator, id, 1, "");

        // Store wrapped NFT state.
        tokenState[id] = TokenState({ creator: tokenCreator, uri: _nftURI, underlyingType: UnderlyingType.ERC721 });

        // Map the native NFT tokenId to the underlying NFT
        erc721WrappedTokens[id] = ERC721Wrapped({ source: _nftContract, tokenId: _tokenId });

        emit ERC721WrappedToken(tokenCreator, _nftContract, _tokenId, id, _nftURI);
    }

    /// @dev Lets a wrapped nft owner redeem the underlying ERC721 NFT.
    function redeemERC721(uint256 _nftId) external {
        // Get redeemer
        address redeemer = _msgSender();

        require(balanceOf(redeemer, _nftId) > 0, "must own token to redeem.");

        // Burn the native NFT token
        _burn(redeemer, _nftId, 1);

        // Transfer the NFT to redeemer
        IERC721(erc721WrappedTokens[_nftId].source).safeTransferFrom(
            address(this),
            redeemer,
            erc721WrappedTokens[_nftId].tokenId
        );

        emit ERC721Redeemed(redeemer, erc721WrappedTokens[_nftId].source, erc721WrappedTokens[_nftId].tokenId, _nftId);
    }

    /// @dev Wraps ERC20 tokens as ERC1155 NFTs.
    function wrapERC20(
        address _tokenContract,
        uint256 _tokenAmount,
        uint256 _numOfNftsToMint,
        string calldata _nftURI
    ) external whenNotPaused onlyMinterRole {
        // Get creator
        address tokenCreator = _msgSender();

        require(IERC20(_tokenContract).balanceOf(tokenCreator) >= _tokenAmount, "owns insufficient amount.");
        require(
            IERC20(_tokenContract).allowance(tokenCreator, address(this)) >= _tokenAmount,
            "must approve transfer."
        );
        require(
            IERC20(_tokenContract).transferFrom(tokenCreator, address(this), _tokenAmount),
            "failed to transfer tokens."
        );

        // Get NFT tokenId
        uint256 id = nextTokenId;
        nextTokenId += 1;

        // Mint NFTs to token creator
        _mint(tokenCreator, id, _numOfNftsToMint, "");

        tokenState[id] = TokenState({ creator: tokenCreator, uri: _nftURI, underlyingType: UnderlyingType.ERC20 });

        erc20WrappedTokens[id] = ERC20Wrapped({
            source: _tokenContract,
            shares: _numOfNftsToMint,
            underlyingTokenAmount: _tokenAmount
        });

        emit ERC20WrappedToken(tokenCreator, _tokenContract, _tokenAmount, _numOfNftsToMint, id, _nftURI);
    }

    /// @dev Lets the nft owner redeem their ERC20 tokens.
    function redeemERC20(uint256 _nftId, uint256 _amount) external {
        // Get redeemer
        address redeemer = _msgSender();

        require(balanceOf(redeemer, _nftId) >= _amount, "must own token to redeem.");

        // Burn the native NFT token
        _burn(redeemer, _nftId, _amount);

        // Get the ERC20 token amount to distribute
        uint256 amountToDistribute = (erc20WrappedTokens[_nftId].underlyingTokenAmount * _amount) /
            erc20WrappedTokens[_nftId].shares;

        // Transfer the ERC20 tokens to redeemer
        require(
            IERC20(erc20WrappedTokens[_nftId].source).transfer(redeemer, amountToDistribute),
            "failed to transfer tokens."
        );

        emit ERC20Redeemed(redeemer, _nftId, erc20WrappedTokens[_nftId].source, amountToDistribute, _amount);
    }

    /// @dev Returns the platform fee bps and recipient.
    function getRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /**
     *      External: setter functions
     */

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "exceed royalty bps");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyModuleAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit NewOwner(_prevOwner, _newOwner);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyModuleAdmin {
        contractURI = _uri;
    }

    /// @dev Lets a protocol admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        isTransferRestricted = _restrictedTransfer;

        emit RestrictedTransferUpdated(_restrictedTransfer);
    }

    /**
     *      Internal functions.
     */

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (isTransferRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }
    }

    /// @dev See EIP-2771
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See EIP-2771
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     *      Rest: view functions
     */

    /// @dev See EIP 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155PresetUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
    }

    /// @dev See EIP 1155
    function uri(uint256 _nftId) public view override returns (string memory) {
        return tokenState[_nftId].uri;
    }
}
