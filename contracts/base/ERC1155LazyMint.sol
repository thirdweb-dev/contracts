// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC1155Base.sol";
import "../extension/LazyMint.sol";

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
    function mintTo(address _to, uint256 _tokenId, string memory, uint256 _amount) public virtual override {
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

        for(uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(_tokenIds[i] < nextTokenIdToMint(), "invalid id");
        }

        _batchMint(_to, _tokenIds, _amounts, "");
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