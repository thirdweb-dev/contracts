// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC1155Base.sol";

import "../../feature/LazyMintUpdated.sol";

import "../../lib/TWStrings.sol";

contract ERC1155LazyMint is ERC1155Base, LazyMintUpdated {

    using TWStrings for uint256;

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
        ERC1155Base(
            _name,
            _symbol,
            _contractURI,
            _royaltyRecipient,
            _royaltyBps
        ) 
    {}

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC1155 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given token id
    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory batchUri = getBaseURI(id);
        return string(abi.encodePacked(batchUri, id.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function batchMint(
        address _to, 
        uint256[] memory _tokenIds, 
        string[] memory, 
        uint256[] memory _amounts, 
        bytes memory _data
    ) public virtual override {
        require(_canMint(), "Not authorized to mint.");

        uint256 tokenIdsLength = _tokenIds.length;

        require(tokenIdsLength == _amounts.length, "unequal length of inputs");

        for(uint256 i = 0; i < tokenIdsLength;) {
            if (_tokenIds[i] == type(uint256).max) {
                require(
                    nextTokenIdToMint < nextTokenIdToLazyMint,
                    "Not enough lazy minted tokens."
                );
                _tokenIds[i] = _nextTokenIdToMint();

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
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}