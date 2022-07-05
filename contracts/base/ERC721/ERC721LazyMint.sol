// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721Base.sol";

import "../../feature/LazyMint.sol";

import "../../lib/TWStrings.sol";

contract ERC721LazyMint is ERC721Base, LazyMint {

    using TWStrings for uint256;

    uint256 public nextTokenIdToLazyMint;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes extraData);

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
        ERC721Base(
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
                        Lazy minting logic
    //////////////////////////////////////////////////////////////*/

    /// @dev lazy mint a batch of tokens
    function lazyMint(
        uint256 amount,
        string calldata baseURIForTokens,
        bytes calldata extraData
    ) external virtual override returns (uint256 batchId) {
        require(amount > 0, "Amount must be greater than 0");
        require(_canLazyMint(), "Not authorized");

        uint256 startId = nextTokenIdToLazyMint;
        (nextTokenIdToLazyMint, batchId) = _batchMint(startId, amount, baseURIForTokens);

        emit TokensLazyMinted(startId, startId + amount, baseURIForTokens, extraData);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    function mint(address _to, string memory _tokenURI, bytes memory _data) public virtual override {
        require(nextTokenIdToMint < nextTokenIdToLazyMint, "No tokens left to mint.");
        require(bytes(_tokenURI).length == 0, "Cannot reassign metadata for token.");

        super.mint(_to, _tokenURI, _data);
    }
}