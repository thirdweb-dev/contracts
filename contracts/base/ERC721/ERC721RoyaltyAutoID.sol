// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721.sol";

import "../../lib/TWStrings.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";

contract ERC721Royalty is 
    ERC721,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty
{
    using TWStrings for uint256;
    
    uint256 public nextTokenIdToMint;
    string public baseURI;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721(_name, _symbol) 
    {
        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function tokenURI(uint256 _tokenId) public virtual view returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "Invalid Id");
        
        string memory _baseURI = baseURI;
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, _tokenId.toString())) : "";
    }

    function mint(address _to, bytes memory _data) external virtual onlyOwner {
       uint256 _id = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        _safeMint(_to, _id, _data);
    }

    function setBaseURI(string memory _baseURI) external virtual onlyOwner {
        // require(bytes(baseURI).length == 0, "Base URI already set");
        baseURI = _baseURI;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal virtual override view returns (bool) {
        return msg.sender == owner();
    }
}
