// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC1155.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";

contract ERC1155Base is 
    ERC1155,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty
{
    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    uint256 public nextTokenIdToMint;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint256) public totalSupply;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
    {
        name = _name;
        symbol = _symbol;

        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function mint(
        address _to, 
        uint256 _tokenId, 
        string memory _tokenURI, 
        uint256 _amount, 
        bytes memory _data
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");

        uint256 tokenIdToMint;
        
        if (_tokenId == type(uint256).max) {
            tokenIdToMint = _nextTokenIdToMint();

            require(bytes(_tokenURI).length > 0, "empty uri.");
            _setTokenURI(tokenIdToMint, _tokenURI);

        } else {
            require(_tokenId < nextTokenIdToMint, "invalid id");
            tokenIdToMint = _tokenId;
        }

        _mint(_to, tokenIdToMint, _amount, _data);
        totalSupply[tokenIdToMint] += _amount;
    }

    function batchMint(
        address _to, 
        uint256[] memory _tokenIds, 
        string[] memory _tokenURIs, 
        uint256[] memory _amounts, 
        bytes memory _data
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");

        uint256 tokenIdsLength = _tokenIds.length;

        require(tokenIdsLength == _tokenURIs.length && tokenIdsLength == _amounts.length, "unequal length of inputs");

        for(uint256 i = 0; i < tokenIdsLength;) {
            if (_tokenIds[i] == type(uint256).max) {
                _tokenIds[i] = _nextTokenIdToMint();

                require(bytes(_tokenURIs[i]).length > 0, "empty uri.");
                _setTokenURI(_tokenIds[i], _tokenURIs[i]);

            } else {
                require(_tokenIds[i] < nextTokenIdToMint, "invalid id");
            }
            
            totalSupply[_tokenIds[i]] += _amounts[i];

            unchecked {
                ++i;
            }
        }
    
        _batchMint(_to, _tokenIds, _amounts, _data);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    function _nextTokenIdToMint() internal virtual returns (uint256) {
        uint256 id = nextTokenIdToMint;
        uint256 startId = _startTokenId();

        if(id < startId) {
            id = startId;
        }

        nextTokenIdToMint = id + 1;

        return id;
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _uri[tokenId] = _tokenURI;
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