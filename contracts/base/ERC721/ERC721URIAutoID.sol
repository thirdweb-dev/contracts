// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";

contract ERC721URIAutoId is 
    ERC721,
    ContractMetadata,
    Multicall,
    Ownable
{
    uint256 public nextTokenIdToMint;
    string public baseURI;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI
    ) ERC721(_name, _symbol) 
    {
        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
    }

    function tokenURI(uint256 _tokenId) public virtual view returns (string memory) {
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

    function setBaseURI(string memory _baseURI) external virtual onlyOwner {
        // require(bytes(baseURI).length == 0, "Base URI already set");
        baseURI = _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(ownerOf(tokenId) != address(0), "Invalid Id");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }
}
