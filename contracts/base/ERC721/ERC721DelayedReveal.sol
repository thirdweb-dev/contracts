// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721LazyMint.sol";

import "../../feature/DelayedReveal.sol";

contract ERC721DelayedReveal is ERC721LazyMint, DelayedReveal {

    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event TokenURIRevealed(uint256 indexed index, string revealedURI);

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
        ERC721LazyMint(
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

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        uint256 batchId = getBatchId(_tokenId);
        string memory batchUri = getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Lazy minting logic
    //////////////////////////////////////////////////////////////*/

    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _encryptedBaseURI
    ) public virtual override returns (uint256 batchId) {
        if (_encryptedBaseURI.length != 0) {
            _setEncryptedBaseURI(nextTokenIdToLazyMint + _amount, _encryptedBaseURI);
        }

        return super.lazyMint(_amount, _baseURIForTokens, _encryptedBaseURI);
    }

    /*//////////////////////////////////////////////////////////////
                        Delayed reveal logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key)
        external
        returns (string memory revealedURI)
    {
        require(_canReveal(), "Not authorized");

        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedBaseURI(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /// @dev Checks whether NFTs can be revealed in the given execution context.
    function _canReveal() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

}