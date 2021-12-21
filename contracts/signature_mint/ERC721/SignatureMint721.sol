// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ISignatureMint721 } from "./ISignatureMint721.sol";

// Token
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Protocol control center.
import { ProtocolControl } from "../../ProtocolControl.sol";

// Signature utils
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// Access Control + security
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Utils
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SignatureMint is
    
    ISignatureMint721,
    ERC721Enumerable,
    EIP712,
    AccessControlEnumerable,
    ERC2771Context,
    IERC2981,
    ReentrancyGuard,
    Multicall

{
    using ECDSA for bytes32;
    using Strings for uint256;

    bytes32 private constant TYPEHASH =
        keccak256("MintRequest(address to,string baseURI,uint256 amountToMint,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes uid)");

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev The address interpreted as native token of the chain.
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of the native token wrapper contract.
    address public immutable nativeTokenWrapper;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The token ID of the next token to mint.
    uint256 public nextTokenIdToMint;

    /// @dev Contract interprets 10_000 as 100%.
    uint64 private constant MAX_BPS = 10_000;

    /// @dev The % of secondary sales collected as royalties. See EIP 2981.
    uint64 public royaltyBps;

    /// @dev The % of primary sales collected by the contract as fees.
    uint120 public feeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    /// @dev Contract level metadata.
    string public contractURI;
    
    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    uint256[] private baseURIIndices;
    
    /// @dev Mapping from end-tokenId => baseURI.
    mapping(uint256 => string) public baseURI;

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes => bool) private minted;

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address payable _controlCenter,
        address _trustedForwarder,
        address _nativeTokenWrapper,
        address _saleRecipient,
        uint128 _royaltyBps,
        uint128 _feeBps
    ) 
        ERC721(_name, _symbol) 
        EIP712(_name, "1")
        ERC2771Context(_trustedForwarder)
    {
        // Set the protocol control center
        controlCenter = ProtocolControl(_controlCenter);
        nativeTokenWrapper = _nativeTokenWrapper;
        defaultSaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        royaltyBps = uint64(_royaltyBps);
        feeBps = uint120(_feeBps);

        address deployer = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINTER_ROLE, deployer);
    }

    ///     =====   Public functions  =====

    /// @dev Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).
    function verify(
        MintRequest calldata req,
        bytes calldata signature
    )
        public
        view 
        returns (bool)
    {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, req.to, req.amountToMint, req.pricePerToken, req.amountToMint, req.validityStartTimestamp, req.validityEndTimestamp, keccak256(req.uid)))
        ).recover(signature);

        return !minted[req.uid] && hasRole(MINTER_ROLE, signer);
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

    ///     =====   External functions  =====

    function mint(MintRequest calldata _req, bytes calldata _signature) external payable {

        verifyRequest(_req, _signature);
        
        uint256 tokenIdToMint = nextTokenIdToMint;

        assignURI(tokenIdToMint, _req.amountToMint, _req.baseURI);

        collectPrice(_req);

        nextTokenIdToMint = mintTokens(_req.to, tokenIdToMint, _req.amountToMint);

        emit TokensMinted(_req, _signature, _msgSender());
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = controlCenter.getRoyaltyTreasury(address(this));
        royaltyAmount = (salePrice * royaltyBps) / MAX_BPS;
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient);
    }

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyBps(uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "bps <= 10000.");

        royaltyBps = uint64(_royaltyBps);

        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setFeeBps(uint256 _feeBps) public onlyModuleAdmin {
        require(_feeBps <= MAX_BPS, "bps <= 10000.");

        feeBps = uint120(_feeBps);

        emit PrimarySalesFeeUpdates(_feeBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

        emit TransfersRestricted(_restrictedTransfer);
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyModuleAdmin {
        contractURI = _uri;
    }

    ///     =====   Internal functions  =====

    function verifyRequest(MintRequest calldata _req, bytes calldata _signature) internal {
        require(
            verify(_req, _signature),
            "not signed off by minter"
        );

        require(
            _req.validityStartTimestamp <= block.timestamp
                && _req.validityEndTimestamp >= block.timestamp,
            "request expired"
        );

        minted[_req.uid] = true;
    }

    function assignURI(
        uint256 _startTokenIdToMint,
        uint256 _amountToMint,
        string memory _baseURI
    ) 
        internal 
    {
        uint256 baseURIIndex = _startTokenIdToMint + _amountToMint;
        baseURI[baseURIIndex] = _baseURI;
        baseURIIndices.push(baseURIIndex);
    }

    function mintTokens(address _receiver, uint256 _startTokenIdToMint, uint256 _amountToMint) internal returns(uint256 nextIdToMint) {
        nextIdToMint = _startTokenIdToMint;

        for(uint256 i = 0; i < _amountToMint; i += 1) {
            _mint(_receiver, nextIdToMint);
            nextIdToMint += 1;
        }
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectPrice(MintRequest memory _req) internal {
        if (_req.pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _req.amountToMint * _req.pricePerToken;
        uint256 fees = (totalPrice * feeBps) / MAX_BPS;

        if (_req.currency == NATIVE_TOKEN) {
            require(msg.value == totalPrice, "must send total price.");
        } else {
            validateERC20BalAndAllowance(_msgSender(), _req.currency, totalPrice);
        }

        transferCurrency(_req.currency, _msgSender(), controlCenter.getRoyaltyTreasury(address(this)), fees);

        transferCurrency(_req.currency, _msgSender(), defaultSaleRecipient, totalPrice - fees);
    }

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                IWETH(nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeToken(_to, _amount);
            } else if (_to == address(this)) {
                require(_amount == msg.value, "native token value does not match bid amount.");
                IWETH(nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeToken(_to, _amount);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(nativeTokenWrapper).deposit{ value: value }();
            safeTransferERC20(nativeTokenWrapper, address(this), to, value);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        uint256 balBefore = IERC20(_currency).balanceOf(_to);
        bool success = IERC20(_currency).transferFrom(_from, _to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(_to);

        require(success && balAfter == balBefore + _amount, "failed to transfer currency.");
    }

    /// @dev Validates that `_addrToCheck` owns and has approved contract to transfer the appropriate amount of currency
    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20(_currency).balanceOf(_addrToCheck) >= _currencyAmountToCheckAgainst &&
                IERC20(_currency).allowance(_addrToCheck, address(this)) >= _currencyAmountToCheckAgainst,
            "insufficient currency balance or allowance."
        );
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
    ) internal virtual override(ERC721Enumerable) {
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
        override(AccessControlEnumerable, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}