// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";

import "../../lib/TWStrings.sol";

contract ERC721ABase is 
    ERC721A,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty
{

    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Largest tokenId of each batch of tokens with the same baseURI.
    uint256[] private batchIds;

    /// @dev Mapping from id of a batch of tokens => to base URI for the respective batch of tokens.
    mapping(uint256 => string) private baseURI;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721A(_name, _symbol) 
    {
        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function mint(
        address _to,
        uint256 _quantity,
        string memory _baseURI,
        bytes memory _data
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");
        
        uint256 batchId = nextTokenIdToMint() + _quantity;
        batchIds.push(batchId);
        baseURI[batchId] = _baseURI;

        _safeMint(_to, _quantity, _data);
    }

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory batchUri = getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                        Public getters
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the number of batches of tokens having the same baseURI.
    function getBaseURICount() public view returns (uint256) {
        return batchIds.length;
    }

    /// @dev Returns the next tokenId that will be issued by the contract.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the baseURI for a token. The intended metadata URI for the token is baseURI + tokenId.
    function getBaseURI(uint256 _tokenId) internal view returns (string memory) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                return baseURI[indices[i]];
            }
        }

        revert("No baseURI for token");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        baseURI[_batchId] = _baseURI;
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