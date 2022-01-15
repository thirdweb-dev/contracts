// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ISignatureMint721 } from "./ISignatureMint721.sol";

// Token
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

// Signature utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

// Access Control + security
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Royalties
import "../../royalty/TWPayments.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Meta transactions
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { MulticallUpgradeable } from "../../openzeppelin-presets/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SignatureMint721 is
    Initializable,
    ISignatureMint721,
    ReentrancyGuardUpgradeable,
    TWPayments,
    EIP712Upgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    bytes32 private constant MODULE_TYPE = keccak256("SIGMINT_ERC721");
    uint256 private constant VERSION = 1;

    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address to,string uri,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The adress that receives all primary sales value.
    address public defaultPlatformFeeRecipient;

    /// @dev The token ID of the next token to mint.
    uint256 public nextTokenIdToMint;

    /// @dev The % of primary sales collected by the contract as fees.
    uint120 public platformFeeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    mapping(uint256 => string) private uri;

    /// @dev Checks whether the caller is a module admin.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    /// @dev Checks whether the caller has MINTER_ROLE.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _;
    }

    constructor(address _nativeTokenWrapper, address _thirdwebFees) TWPayments(_nativeTokenWrapper, _thirdwebFees) {}

    /// @dev Initiliazes the contract, like a constructor.
    function intialize(
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
        __TWPayments_init(_royaltyReceiver, uint96(_royaltyBps));
        __EIP712_init("SignatureMint721", "1");
        __ERC2771Context_init(_trustedForwarder);
        __Multicall_init();
        __AccessControlEnumerable_init();
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        // Initialize this contract's state.
        defaultPlatformFeeRecipient = _platformFeeRecipient;
        defaultSaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        royaltyBps = uint64(_royaltyBps);
        platformFeeBps = uint120(_platformFeeBps);

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
    function version() external pure returns (uint256) {
        return VERSION;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).
    function verify(MintRequest calldata _req, bytes calldata _signature) public view returns (bool, address) {
        address signer = recoverAddress(_req, _signature);
        return (!minted[_req.uid] && hasRole(MINTER_ROLE, signer), signer);
    }

    /// @dev Returns the URI for a tokenId
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return uri[_tokenId];
    }

    /// @dev Lets an account with MINTER_ROLE mint an NFT.
    function mintTo(address _to, string calldata _uri) external onlyMinter returns (uint256) {
        // `_mintTo` is re-used. `mintTo` just adds a minter role check.
        return _mintTo(_to, _uri);
    }

    ///     =====   External functions  =====

    /// @dev Mints an NFT according to the provided mint request.
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        nonReentrant
        returns (uint256 tokenIdMinted)
    {
        address signer = verifyRequest(_req, _signature);
        address receiver = _req.to == address(0) ? _msgSender() : _req.to;

        tokenIdMinted = _mintTo(receiver, _req.uri);

        collectPrice(_req);

        emit MintWithSignature(signer, receiver, tokenIdMinted, _req);
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient);
    }

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultPlatformFeeRecipient(address _platformFeeRecipient) external onlyModuleAdmin {
        defaultPlatformFeeRecipient = _platformFeeRecipient;
        emit NewPlatformFeeRecipient(_platformFeeRecipient);
    }

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyBps(uint256 _royaltyBps) public onlyModuleAdmin {
        _setRoyaltyBps(_royaltyBps);
    }

    /// @dev Lets a module admin set the royalty recipient.
    function setRoyaltyRecipient(address _royaltyRecipient) external onlyModuleAdmin {
        _setRoyaltyRecipient(_royaltyRecipient);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatfromFeeBps(uint256 _platformFeeBps) public onlyModuleAdmin {
        require(_platformFeeBps <= MAX_BPS, "bps <= 10000.");

        platformFeeBps = uint120(_platformFeeBps);

        emit PlatformFeeUpdates(_platformFeeBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

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

    ///     =====   Internal functions  =====

    /// @dev Mints an NFT to `to`
    function _mintTo(address _to, string calldata _uri) internal returns (uint256 tokenIdToMint) {
        tokenIdToMint = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        uri[tokenIdToMint] = _uri;

        _mint(_to, tokenIdToMint);

        emit TokenMinted(_to, tokenIdToMint, _uri);
    }

    /// @dev Returns the address of the signer of the mint request.
    function recoverAddress(MintRequest calldata _req, bytes calldata _signature) internal view returns (address) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        TYPEHASH,
                        _req.to,
                        keccak256(bytes(_req.uri)),
                        _req.price,
                        _req.currency,
                        _req.validityStartTimestamp,
                        _req.validityEndTimestamp,
                        _req.uid
                    )
                )
            ).recover(_signature);
    }

    /// @dev Verifies that a mint request is valid.
    function verifyRequest(MintRequest calldata _req, bytes calldata _signature) internal returns (address) {
        (bool success, address signer) = verify(_req, _signature);
        require(success, "invalid signature");

        require(
            _req.validityStartTimestamp <= block.timestamp && _req.validityEndTimestamp >= block.timestamp,
            "request expired"
        );

        minted[_req.uid] = true;

        return signer;
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectPrice(MintRequest memory _req) internal {
        if (_req.price == 0) {
            return;
        }

        uint256 totalPrice = _req.price;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
        uint256 twFee = (totalPrice * thirdwebFees.getSalesFeeBps(address(this))) / MAX_BPS;

        if (_req.currency == NATIVE_TOKEN) {
            require(msg.value == _req.price, "must send total price.");
        }
        transferCurrency(_req.currency, _msgSender(), defaultPlatformFeeRecipient, platformFees);
        transferCurrency(_req.currency, _msgSender(), thirdwebFees.getSalesFeeRecipient(address(this)), twFee);
        transferCurrency(_req.currency, _msgSender(), defaultSaleRecipient, totalPrice - platformFees - twFee);
    }

    ///     =====   Low-level overrides  =====

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
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, TWPayments)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
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
