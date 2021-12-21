// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ISignatureMint } from "./ISignatureMint.sol";

// Token
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Protocol control center.
import { ProtocolControl } from "../ProtocolControl.sol";

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

contract SignatureMint is
    
    ISignatureMint,
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
        keccak256("MintRequest(address to,string baseURI,uint256 amountToMint,uint256 validityStartTimestamp,uint256 validityEndTimestamp,bytes uid)");

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

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
        uint128 _royaltyBps,
        uint128 _feeBps
    ) 
        ERC721(_name, _symbol) 
        EIP712(_name, "1")
        ERC2771Context(_trustedForwarder)
    {
        // Set the protocol control center
        controlCenter = ProtocolControl(_controlCenter);
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
            keccak256(abi.encode(TYPEHASH, req.to, req.amountToMint, req.validityStartTimestamp, req.validityEndTimestamp, keccak256(req.uid)))
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

    function mint(MintRequest calldata _req, bytes calldata _signature) external {

        verifyRequest(_req, _signature);
        
        uint256 tokenIdToMint = nextTokenIdToMint;

        assignURI(tokenIdToMint, _req.amountToMint, _req.baseURI);

        nextTokenIdToMint = mintTokens(_req.to, tokenIdToMint, _req.amountToMint);
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

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyBps(uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "bps <= 10000.");

        royaltyBps = uint64(_royaltyBps);

        // emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setFeeBps(uint256 _feeBps) public onlyModuleAdmin {
        require(_feeBps <= MAX_BPS, "bps <= 10000.");

        feeBps = uint120(_feeBps);

        // emit PrimarySalesFeeUpdates(_feeBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

        // emit TransfersRestricted(_restrictedTransfer);
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