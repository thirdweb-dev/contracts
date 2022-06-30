// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "./ERC721A.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";

// import "../eip/interface/IERC721Metadata.sol";

contract ERC721ABase is 
    ERC721A,
    ContractMetadata,
    Multicall
{
    uint256 public nextTokenIdToMint;
    string public baseURI;
    address private _owner;

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    function tokenURI(uint256 _tokenId) public virtual override view returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "Invalid Id");

        string memory _tokenURI = _tokenURIs[_tokenId];
        string memory base = baseURI;

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return base;
    }

    function mint(address _to, string memory _tokenURI, bytes memory _data) external virtual onlyOwner {
        uint256 _id = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        _safeMint(_to, _id, _data);
        _setTokenURI(_id, _tokenURI);
    }

    function burn(uint256 _id) external virtual {
        address tokenOwner = ownerOf(_id);

        require(tokenOwner != address(0), "Invalid Id");
        require(msg.sender == tokenOwner || isApprovedForAll[tokenOwner][msg.sender] || msg.sender == getApproved[_id], "NOT_AUTHORIZED");
        
        _burn(_id);
    }


    function setBaseURI(string memory _baseURI) external virtual onlyOwner {
        // require(bytes(baseURI).length == 0, "Base URI already set");
        baseURI = _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(ownerOf(tokenId) != address(0), "Invalid Id");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _canSetContractURI() internal override returns (bool) {
        return msg.sender == _owner;
    }
}
