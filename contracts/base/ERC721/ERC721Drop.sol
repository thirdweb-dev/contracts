// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";
import "../../feature/DropSinglePhase.sol";

contract ERC721Drop is 
    ERC721,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty,
    DropSinglePhase
{
    using Strings for uint256;

    uint256 public nextTokenIdToMint;

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

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function tokenURI(uint256 _tokenId) public virtual view returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "Invalid Id");

        string memory batchUri = getBaseURI(_tokenId);

        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata
    ) external onlyOwner returns (uint256 batchId) {
        uint256 startId = nextTokenIdToMint;

        (nextTokenIdToMint, batchId) = _batchMint(startId, _amount, _baseURIForTokens);

        // emit TokensLazyMinted(startId, startId + _amount, _baseURIForTokens, "");
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override
    {

    }

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual view override returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal virtual override view returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal virtual override view returns (bool) {
        return msg.sender == owner;
    }
}
