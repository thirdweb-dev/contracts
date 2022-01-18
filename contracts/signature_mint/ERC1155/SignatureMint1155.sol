// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ISignatureMint1155 } from "./ISignatureMint1155.sol";

// Token
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

// Signature utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

// Access Control + security
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../../royalty/TWPayments.sol";

// Meta transactions
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { MulticallUpgradeable } from "../../openzeppelin-presets/utils/MulticallUpgradeable.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SignatureMint1155 is
    Initializable,
    ISignatureMint1155,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    TWPayments,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    bytes32 private constant MODULE_TYPE = keccak256("SIGMINT_ERC1155");
    uint256 private constant VERSION = 1;

    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address to,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev The next token ID of the NFT to mint.
    uint256 public nextTokenIdToMint;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The adress that receives all primary sales value.
    address public defaultPlatformFeeRecipient;

    /// @dev The % of primary sales collected by the contract as fees.
    uint128 public platformFeeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    mapping(uint256 => string) private _tokenURI;

    /// @dev Token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Token ID => the address of the recipient of primary sales.
    mapping(uint256 => address) public saleRecipient;

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
        __TWPayments_init(_royaltyReceiver, _royaltyBps);
        __EIP712_init("SignatureMint1155", "1");
        __ERC2771Context_init(_trustedForwarder);
        __Multicall_init();
        __AccessControlEnumerable_init();
        __ERC1155_init("");
        // Initialize this contract's state.
        defaultPlatformFeeRecipient = _platformFeeRecipient;
        defaultSaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        royaltyBps = _royaltyBps;
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
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return _tokenURI[_tokenId];
    }

    /// @dev Returns the URI for a tokenId
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return _tokenURI[_tokenId];
    }

    /// @dev Lets an account with MINTER_ROLE mint an NFT.
    function mintTo(
        address _to,
        string calldata _uri,
        uint256 _amount
    ) external onlyMinter {
        uint256 tokenIdToMint = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        // `_mintTo` is re-used. `mintTo` just adds a minter role check.
        _mintTo(_to, _uri, tokenIdToMint, _amount);
    }

    ///     =====   External functions  =====

    /// @dev Mints an NFT according to the provided mint request.
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature) external payable nonReentrant {
        address signer = verifyRequest(_req, _signature);
        address receiver = _req.to == address(0) ? _msgSender() : _req.to;

        uint256 tokenIdToMint;
        if (_req.tokenId == type(uint256).max) {
            tokenIdToMint = nextTokenIdToMint;
            nextTokenIdToMint += 1;
        } else {
            require(_req.tokenId < nextTokenIdToMint, "invalid id");
            tokenIdToMint = _req.tokenId;
        }

        _mintTo(receiver, _req.uri, tokenIdToMint, _req.quantity);

        collectPrice(_req, tokenIdToMint);

        emit MintWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the recipient of all primary sales for a given token ID.
    function setSaleRecipient(uint256 _tokenId, address _saleRecipient) external onlyModuleAdmin {
        saleRecipient[_tokenId] = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient, _tokenId, false);
    }

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewDefaultSaleRecipient(_saleRecipient);
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
    function setPlatformFeeBps(uint256 _platformFeeBps) public onlyModuleAdmin {
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
    function _mintTo(
        address _to,
        string calldata _uri,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        if (bytes(_tokenURI[_tokenId]).length == 0) {
            require(bytes(_uri).length > 0, "empty uri.");
            _tokenURI[_tokenId] = _uri;
        }

        _mint(_to, _tokenId, _amount, "");

        emit TokenMinted(_to, _tokenId, _tokenURI[_tokenId], _amount);
    }

    /// @dev Returns the address of the signer of the mint request.
    function recoverAddress(MintRequest calldata _req, bytes calldata _signature) internal view returns (address) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        TYPEHASH,
                        _req.to,
                        _req.tokenId,
                        keccak256(bytes(_req.uri)),
                        _req.quantity,
                        _req.pricePerToken,
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
    function collectPrice(MintRequest memory _req, uint256 _tokenId) internal {
        if (_req.pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _req.pricePerToken * _req.quantity;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
        uint256 twFee = (totalPrice * thirdwebFees.getSalesFeeBps(address(this))) / MAX_BPS;

        if (_req.currency == NATIVE_TOKEN) {
            require(msg.value == totalPrice, "must send total price.");
        }

        address recipient = saleRecipient[_tokenId] == address(0) ? defaultSaleRecipient : saleRecipient[_tokenId];

        transferCurrency(_req.currency, _msgSender(), defaultPlatformFeeRecipient, platformFees);
        transferCurrency(_req.currency, _msgSender(), thirdwebFees.getSalesFeeRecipient(address(this)), twFee);
        transferCurrency(_req.currency, _msgSender(), recipient, totalPrice - platformFees - twFee);
    }

    ///     =====   Low-level overrides  =====

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (transfersRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders.");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable, TWPayments)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
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
