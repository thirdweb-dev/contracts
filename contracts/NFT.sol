// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Token + Access Control
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract NFT is ERC721PresetMinterPauserAutoId, ERC2771Context, IERC2981 {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev The token Id of the NFT to mint.
    uint256 public nextTokenId;

    /// @dev Collection level metadata.
    string public _contractURI;

    bool public isRestrictedTransfer;

    /// @dev Mapping from tokenId => URI
    mapping(uint256 => string) public nftURI;

    /// @dev Mapping from tokenId => creator
    mapping(uint256 => address) public nftCreator;

    /// @dev Pack sale royalties -- see EIP 2981
    uint256 public royaltyBps;

    /// @dev Emitted when an NFT is minted;
    event Minted(address indexed creator, address indexed to, uint256 tokenId, string tokenURI);
    event MintedBatch(address indexed creator, address indexed to, uint256[] tokenIds, string[] tokenURI);

    event RoyaltyUpdated(uint256 royaltyBps);

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "NFT: only a protocol admin can call this function."
        );
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "NFT: The protocol is paused.");
        _;
    }

    constructor(
        address payable _controlCenter,
        string memory _name,
        string memory _symbol,
        address _trustedForwarder,
        string memory _uri
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _uri) ERC2771Context(_trustedForwarder) {
        // Set the protocol control center
        controlCenter = ProtocolControl(_controlCenter);

        // Set contract URI
        _contractURI = _uri;

        _setupRole(TRANSFER_ROLE, _msgSender());
    }

    /// @dev Revert inherited mint function.
    function mint(address) public pure override {
        revert("NFT721: Call mintNFT instead.");
    }

    /// @dev Mints an NFT to `_to` with URI `_uri`
    function mintNFT(address _to, string calldata _uri) external onlyUnpausedProtocol {
        require(hasRole(MINTER_ROLE, _msgSender()), "NFT: must have minter role to mint");

        // Get tokenId
        uint256 id = nextTokenId;

        // Update URI
        nftURI[id] = _uri;

        // Update creator
        nftCreator[id] = _msgSender();

        // Mint NFT
        _mint(_to, id);
        nextTokenId += 1;

        emit Minted(_msgSender(), _to, id, _uri);
    }

    function mintNFTBatch(address _to, string[] calldata _uris) external onlyUnpausedProtocol {
        require(hasRole(MINTER_ROLE, _msgSender()), "NFT: must have minter role to mint");

        uint256[] memory ids = new uint256[](_uris.length);

        // Get tokenId
        uint256 id = nextTokenId;
        address creator = _msgSender();

        for (uint256 i = 0; i < _uris.length; i++) {
            // Update Ids
            ids[i] = id;

            // Update URI
            nftURI[id] = _uris[i];

            // Update creator
            nftCreator[id] = creator;

            // Mint NFT
            _mint(_to, id);

            id += 1;
        }

        nextTokenId = id;

        emit MintedBatch(creator, _to, ids, _uris);
    }

    /// @dev Lets a protocol admin update the royalties paid on pack sales.
    function setRoyaltyBps(uint256 _royaltyBps) external onlyProtocolAdmin {
        require(
            _royaltyBps < (controlCenter.MAX_BPS() + controlCenter.MAX_PROVIDER_FEE_BPS()),
            "NFT: Bps provided must be less than 9,000"
        );

        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyBps);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721PresetMinterPauserAutoId, IERC165)
        returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    function setRestrictedTransfer(bool _restrictedTransfer) external onlyProtocolAdmin {
        isRestrictedTransfer = _restrictedTransfer;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PresetMinterPauserAutoId) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (isRestrictedTransfer) {
            require(
                hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to),
                "NFT: Transfers are restricted to TRANSFER_ROLE holders"
            );
        }
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = nftCreator[tokenId];
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return nftURI[tokenId];
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
