// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC1155Base.sol";
import "../extension/LazyMint.sol";

/**
 *      BASE:      ERC1155Base
 *      EXTENSION: LazyMint
 *
 *  The `ERC1155LazyMint` contract uses the `ERC1155Base` contract, along with the `LazyMint` extension.
 *
 *  'Lazy minting' means defining the metadata of NFTs without minting it to an address. Regular 'minting'
 *  of  NFTs means actually assigning an owner to an NFT.
 *
 *  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,
 *  without paying the gas cost for actually minting the NFTs.
 *
 */

contract ERC1155LazyMint is ERC1155Base, LazyMint {
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {}

    /*//////////////////////////////////////////////////////////////
                        OVERRIDEN MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint lazy minted NFTs to a recipient.
     *  @dev             - The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFTs to mint.
     *  @param _tokenId  The tokenId of the lazy minted NFT to mint.
     *  @param _amount   The amount of the same NFT to mint.
     */
    function mintTo(
        address _to,
        uint256 _tokenId,
        string memory,
        uint256 _amount
    ) public virtual override {
        require(_canMint(), "Not authorized to mint.");
        require(_tokenId < nextTokenIdToMint(), "invalid id");

        _mint(_to, _tokenId, _amount, "");
    }

    /**
     *  @notice          Lets an authorized address mint multiple lazy minted NFTs at once to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenIds The tokenIds of the NFTs to mint.
     *  @param _amounts  The amounts of each NFT to mint.
     */
    function batchMintTo(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        string memory
    ) public virtual override {
        require(_canMint(), "Not authorized to mint.");
        require(_amounts.length > 0, "Minting zero tokens.");
        require(_tokenIds.length == _amounts.length, "Length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(_tokenIds[i] < nextTokenIdToMint(), "invalid id");
        }

        _mintBatch(_to, _tokenIds, _amounts, "");
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual override returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /*//////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
