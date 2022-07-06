// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721ABase.sol";

import "../../feature/LazyMintUpdated.sol";

import "../../lib/TWStrings.sol";

contract ERC721LazyMint is ERC721ABase, LazyMintUpdated {

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
        ERC721ABase(
            _name,
            _symbol,
            contractURI,
            _royaltyRecipient,
            _royaltyBps
        ) 
    {}

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory batchUri = getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function mint(
        address _to,
        uint256 _quantity,
        string memory,
        bytes memory _data
    ) public virtual override {
        require(_canMint(), "Not authorized to mint.");
        require(
            nextTokenIdToMint() + _quantity <= nextTokenIdToLazyMint,
            "Not enough lazy minted tokens."
        );

        _safeMint(_to, _quantity, _data);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}