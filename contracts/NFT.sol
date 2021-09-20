// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Token + Access Control
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract NFT is ERC721PresetMinterPauserAutoId, ERC2771Context {

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev The token Id of the NFT to mint.
    uint256 public nextTokenId;

    /// @dev Collection level metadata.
    string public _contractURI;

    /// @dev Mapping from tokenId => URI
    mapping(uint => string) public nftURI;

    /// @dev Emitted when an NFT is minted;
    event Minted(address indexed to, uint tokenId, string tokenURI);

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "NFT721: only a protocol admin can call this function."
        );
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "NFT721: The protocol is paused.");
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
    }

    /// @dev Revert inherited mint function.
    function mint(address) public pure override {
        revert("NFT721: Call mintNFT instead.");
    }

    /// @dev Mints an NFT to `_to` with URI `_uri`
    function mintNFT(address _to, string calldata _uri) external onlyUnpausedProtocol {
        require(hasRole(MINTER_ROLE, _msgSender()), "NFT721: must have minter role to mint");

        // Get tokenId
        uint id = nextTokenId;
        
        // Mint NFT
        _mint(_to, id);
        nextTokenId += 1;

        // Update URI
        nftURI[id] = _uri;

        emit Minted(_to, id, _uri);
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
