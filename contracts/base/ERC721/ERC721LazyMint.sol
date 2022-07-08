// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721ABase.sol";

import "../../extension/LazyMintUpdated.sol";

import "../../lib/TWStrings.sol";

/**
 *      BASE:      ERC721ABase
 *      EXTENSION: LazyMint
 *
 *  The `ERC721LazyMint` contract uses the `ERC721ABase` contract, along with the `LazyMint` extension.
 *
 *  'Lazy minting' means defining the metadata of NFTs without minting it to an address. Regular 'minting'
 *  of  NFTs means actually assigning an owner to an NFT.
 *
 *  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,
 *  without paying the gas cost for actually minting the NFTs.
 *  
 */

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