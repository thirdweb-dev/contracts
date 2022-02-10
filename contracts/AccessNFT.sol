// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Base
import "./openzeppelin-presets/ERC1155PresetUpgradeable.sol";
import "./interfaces/IThirdwebModule.sol";
import "./interfaces/IThirdwebOwnable.sol";

// Meta transactions
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "./openzeppelin-presets/utils/MulticallUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";
import "./lib/FeeType.sol";

// Helper interfaces
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Thirdweb top-level
import "./TWFee.sol";

contract AccessNFT is
    IERC2981,
    IThirdwebModule,
    IThirdwebOwnable,
    Initializable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC1155PresetUpgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("AccessNFT");
    uint256 private constant VERSION = 1;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

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

    /// @dev Whether AccessNFTs (where TokenState.isRedeemable == false) are transferable.
    bool public accessNftIsTransferable;

    /// @dev the URI for the storefront-level metadata of the contract.
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
        bool isRedeemable;
        uint256 accessNftId;
        UnderlyingType underlyingType;
    }

    /// @dev Emmitted when Access NFTs are created.
    event AccessNFTsCreated(
        address indexed creator,
        uint256[] nftIds,
        string[] nftURIs,
        uint256[] acessNftIds,
        string[] accessNftURIs,
        uint256[] nftSupplies
    );

    /// @dev Emitted when an Access NFT is redeemed.
    event AccessNFTRedeemed(
        address indexed redeemer,
        uint256 indexed nftTokenId,
        uint256 indexed accessNftId,
        uint256 amount
    );

    /// @dev Emitted when restrictions on transfers is updated.
    event RestrictedTransferUpdated(bool transferable);

    /// @dev Emitted when the last time to redeem an Access NFT is updated.
    event LastRedeemTimeUpdated(uint256 accessNftId, address creator, uint256 lastTimeToRedeem);

    /// @dev Emitted when the transferability of Access NFTs is changed.
    event AccessTransferabilityUpdated(bool isTransferable);

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

    /// @dev Access NFT tokenId => final redemption timestamp.
    mapping(uint256 => uint256) public lastTimeToRedeem;

    /// @dev Checks whether the caller is a module admin.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
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
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarder);
        __ERC1155Preset_init(_defaultAdmin, _contractURI);

        // Initialize this contract's state.
        name = _name;
        symbol = _symbol;
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = _royaltyBps;
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

    /// @dev See EIP 1155
    function uri(uint256 _nftId) public view override returns (string memory) {
        return tokenState[_nftId].uri;
    }

    /// @dev Alternative function to return a token's URI
    function tokenURI(uint256 _nftId) public view returns (string memory) {
        return tokenState[_nftId].uri;
    }

    /// @dev Returns whether a token represent is redeemable.
    function isRedeemable(uint256 _nftId) public view returns (bool) {
        return tokenState[_nftId].isRedeemable;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
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
        for (uint256 i = 0; i < ids.length; ++i) {
            if (ids[i] >= nextTokenId) {
                revert("cannot mint new NFTs.");
            }

            if (tokenState[ids[i]].underlyingType != UnderlyingType.None) {
                revert("cannot freely mint more ERC20 or ERC721.");
            }
        }

        super.mintBatch(to, ids, amounts, data);
    }

    /**
     *      External functions.
     */

    /// @dev See EIP-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (salePrice * royaltyBps ) / MAX_BPS;
    }

    /// @notice Create native ERC 1155 NFTs.
    function createAccessTokens(
        address to,
        string[] calldata _nftURIs,
        string[] calldata _accessNftURIs,
        uint256[] calldata _nftSupplies,
        bytes calldata data
    ) external whenNotPaused onlyMinterRole {
        require(
            _nftURIs.length == _nftSupplies.length && _nftURIs.length == _accessNftURIs.length,
            "unequal lengths of configs."
        );
        require(_nftURIs.length > 0, "cannot mint 0 NFTs.");

        // Get tokenIds.
        uint256[] memory nftIds = new uint256[](_nftURIs.length);
        uint256[] memory accessNftIds = new uint256[](_nftURIs.length);

        uint256 id = nextTokenId;

        // Store NFT state for each NFT.
        for (uint256 i = 0; i < _nftURIs.length; i++) {
            // Store Access NFT tokenId
            accessNftIds[i] = id;

            // Store Access NFT info
            tokenState[id] = TokenState({
                creator: _msgSender(),
                uri: _accessNftURIs[i],
                isRedeemable: false,
                accessNftId: 0,
                underlyingType: UnderlyingType.None
            });

            // Update id
            id += 1;

            // Store NFT tokenId
            nftIds[i] = id;

            // Store NFT info
            tokenState[id] = TokenState({
                creator: _msgSender(),
                uri: _nftURIs[i],
                isRedeemable: true,
                accessNftId: (id - 1),
                underlyingType: UnderlyingType.None
            });

            // Update id
            id += 1;
        }

        nextTokenId = id;

        // Mint Access NFTs (Redeemed) to contract
        _mintBatch(address(this), accessNftIds, _nftSupplies, "");

        // Mint NFTs (Redeemable) to `to`
        _mintBatch(to, nftIds, _nftSupplies, data);

        emit AccessNFTsCreated(_msgSender(), nftIds, _nftURIs, accessNftIds, _accessNftURIs, _nftSupplies);
    }

    /// @dev Lets a redeemable token holder to redeem token.
    function redeemToken(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        // Get redeemer
        address redeemer = _msgSender();

        require(tokenState[_tokenId].isRedeemable, "token not redeemable.");
        require(balanceOf(redeemer, _tokenId) >= _amount && _amount > 0, "redeeming more than owned.");
        require(
            block.timestamp <= lastTimeToRedeem[_tokenId] || lastTimeToRedeem[_tokenId] == 0,
            "window to redeem closed."
        );

        // Burn NFTs of the 'unredeemed' state.
        burn(redeemer, _tokenId, _amount);

        // Get access nft Id
        uint256 accessNftId = tokenState[_tokenId].accessNftId;

        // Transfer Access NFTs to redeemer
        this.safeTransferFrom(address(this), redeemer, accessNftId, _amount, "");

        emit AccessNFTRedeemed(redeemer, _tokenId, accessNftId, _amount);
    }

    /// @dev Returns the platform fee bps and recipient.
    function getRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /**
     *      External: setter functions
     */

    /// @dev Lets an Access NFT creator set a limit for when the reward can be redeemed.
    function setLastTimeToRedeem(uint256 _tokenId, uint256 _secondsUntilRedeem) external {
        require(_msgSender() == tokenState[_tokenId].creator, "not creator.");
        require(tokenState[_tokenId].isRedeemable, "setting redeem time for non-redeemable NFTs.");

        uint256 lastTimeToRedeemNFT = _secondsUntilRedeem == 0
            ? type(uint256).max
            : block.timestamp + _secondsUntilRedeem;
        lastTimeToRedeem[_tokenId] = lastTimeToRedeemNFT;

        emit LastRedeemTimeUpdated(_tokenId, _msgSender(), lastTimeToRedeemNFT);
    }

    /// @dev Lets the protocol admin set the transferability of Access NFTs.
    function setAccessNftTransferability(bool _isTransferable) external onlyModuleAdmin {
        accessNftIsTransferable = _isTransferable;

        emit AccessTransferabilityUpdated(_isTransferable);
    }

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "exceed royalty bps");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a protocol admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        isTransferRestricted = _restrictedTransfer;

        emit RestrictedTransferUpdated(_restrictedTransfer);
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

    /**
     *      Internal functions.
     */

    /// @dev Sets retrictions on upgrades.

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

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (isTransferRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            if (!tokenState[ids[i]].isRedeemable && !accessNftIsTransferable) {
                require(from == address(0) || from == address(this), "transfers restricted on redeemed NFTs.");
            }
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

    /// @dev See EIP 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155PresetUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
    }
}
