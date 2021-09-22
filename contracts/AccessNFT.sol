// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Access Control
import "@openzeppelin/contracts/access/Ownable.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract AccessNFT is ERC1155PresetMinterPauser, ERC2771Context, IERC2981 {
    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev The token Id of the NFT to mint.
    uint256 public nextTokenId;

    /// @dev NFT sale royalties -- see EIP 2981
    uint256 public royaltyBps;

    /// @dev Collection level metadata.
    string public _contractURI;

    enum UnderlyingType {
        None,
        ERC20,
        ERC721,
        ERC1155
    }

    struct NftInfo {
        address creator;
        string uri;
        uint256 supply;
        uint256 accessNftId;
        UnderlyingType underlyingType;
    }

    struct AccessNftInfo {
        address creator;
        string uri;
        uint256 supply;
    }

    /// @notice Events.
    event AccessNFTsCreated(
        address indexed creator,
        uint256[] nftIds,
        string[] nftURIs,
        uint256[] acessNftIds,
        string[] accessNftURIs,
        uint256[] nftSupplies
    );
    event AccessNFTRedeemed(
        address indexed redeemer,
        uint256 indexed nftTokenId,
        uint256 indexed accessNftId,
        uint256 amount
    );
    event RoyaltyUpdated(uint256 royaltyBps);

    /// @dev NFT tokenId => NFT state.
    mapping(uint256 => NftInfo) public nftInfo;

    /// @dev Access NFT tokenId => Access NFT state.
    mapping(uint256 => AccessNftInfo) public accessNftInfo;

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "NFT: The protocol is paused.");
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "NFT: only a protocol admin can call this function."
        );
        _;
    }

    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri
    ) ERC1155PresetMinterPauser(_uri) ERC2771Context(_trustedForwarder) {
        // Set the protocol control center
        controlCenter = ProtocolControl(_controlCenter);

        // Set contract URI
        _contractURI = _uri;
    }

    /// @notice Create native ERC 1155 NFTs.
    function createAccessNfts(
        string[] calldata _nftURIs,
        string[] calldata _accessNftURIs,
        uint256[] calldata _nftSupplies
    ) public onlyUnpausedProtocol returns (uint256[] memory nftIds) {
        require(
            _nftURIs.length == _nftSupplies.length && _nftURIs.length == _accessNftURIs.length,
            "NFT: Must specify equal number of config values."
        );
        require(_nftURIs.length > 0, "NFT: Must create at least one NFT.");

        // Get tokenIds.
        nftIds = new uint256[](_nftURIs.length);
        uint256[] memory accessNftIds = new uint256[](_nftURIs.length);

        uint256 id = nextTokenId;

        // Store NFT state for each NFT.
        for (uint256 i = 0; i < _nftURIs.length; i++) {
            // Store NFT tokenId
            accessNftIds[i] = id;

            // Store NFT info
            accessNftInfo[id] = AccessNftInfo({ creator: _msgSender(), uri: _nftURIs[i], supply: _nftSupplies[i] });

            // Update id
            id += 1;

            // Store NFT tokenId
            nftIds[i] = id;

            // Store NFT info
            nftInfo[id] = NftInfo({
                creator: _msgSender(),
                uri: _nftURIs[i],
                supply: _nftSupplies[i],
                accessNftId: (id - 1),
                underlyingType: UnderlyingType.ERC1155
            });

            // Update id
            id += 1;
        }

        nextTokenId = id;

        // Mint Access NFTs to contract
        _mintBatch(address(this), accessNftIds, _nftSupplies, "");

        // Mint NFTs to `_msgSender()`
        _mintBatch(_msgSender(), nftIds, _nftSupplies, "");

        emit AccessNFTsCreated(_msgSender(), nftIds, _nftURIs, accessNftIds, _accessNftURIs, _nftSupplies);
    }

    /// @dev Creates packs with NFT.
    function createAccessPack(
        address _pack,
        string[] calldata _nftURIs,
        string[] calldata _accessNftURIs,
        uint256[] calldata _nftSupplies,
        string calldata _packURI,
        uint256 _secondsUntilOpenStart,
        uint256 _secondsUntilOpenEnd,
        uint256 _nftsPerOpen
    ) external onlyUnpausedProtocol {
        uint256[] memory nftIds = createAccessNfts(_nftURIs, _accessNftURIs, _nftSupplies);

        bytes memory args = abi.encode(_packURI, _secondsUntilOpenStart, _secondsUntilOpenEnd, _nftsPerOpen);
        safeBatchTransferFrom(_msgSender(), _pack, nftIds, _nftSupplies, args);
    }

    /// @dev Lets an NFT holder redeem the underlying Access NFT.
    function redeemAccess(uint256 _tokenId, uint256 _amount) external onlyUnpausedProtocol {
        // Get redeemer
        address redeemer = _msgSender();

        require(balanceOf(redeemer, _tokenId) >= _amount, "AccessNFT: Cannot redeem more NFTs than owned.");

        // Transfer NFTs to this contract
        safeTransferFrom(redeemer, address(this), _tokenId, _amount, "");

        // Get access nft Id
        uint256 accessNftId = nftInfo[_tokenId].accessNftId;

        // Transfer Access NFTs to redeemer
        safeTransferFrom(address(this), redeemer, accessNftId, _amount, "");

        emit AccessNFTRedeemed(redeemer, _tokenId, accessNftId, _amount);
    }

    /// @dev Lets a protocol admin update the royalties paid on pack sales.
    function setRoyaltyBps(uint256 _royaltyBps) external onlyProtocolAdmin {
        require(_royaltyBps < controlCenter.MAX_BPS(), "NFT: Bps provided must be less than 10,000");

        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    /// @dev Updates a token's total supply.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Decrease total supply if tokens are being burned.
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                nftInfo[ids[i]].supply -= amounts[i];
            }
        }
    }

    /// @dev See EIP 2918
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = nftInfo[tokenId].creator;
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }

    /// @dev See EIP 1155
    function uri(uint256 _nftId) public view override returns (string memory) {
        return nftInfo[_nftId].uri;
    }

    /// @dev Alternative function to return a token's URI
    function tokenURI(uint256 _nftId) public view returns (string memory) {
        return nftInfo[_nftId].uri;
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev ERC2771Context override
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    /// @dev ERC2771Context override
    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
