// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";

contract ERC721Base is 
    ERC721,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty
{
    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    uint256 private nextId;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function mint(address _to, string memory _tokenURI, bytes memory _data) public virtual {
        require(_canMint(), "Not authorized to mint.");
        
        uint256 _id = _nextTokenIdToMint();

        _safeMint(_to, _id, _data);
        _setTokenURI(_id, _tokenURI);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    function _nextTokenIdToMint() internal virtual returns (uint256) {
        uint256 id = nextId;
        uint256 startId = _startTokenId();

        if(id < startId) {
            id = startId;
        }

        nextId = id + 1;

        return id;
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _setTokenURI(uint256 tokenId, string memory _uri) internal virtual {
        require(ownerOf(tokenId) != address(0), "Invalid Id");
        _tokenURI[tokenId] = _uri;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint() internal virtual view returns (bool) {
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
