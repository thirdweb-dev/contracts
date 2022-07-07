// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";

/**
 *  The `ERC721Base` smart contract implements the ERC721 NFT standard. It includes the following additions to standard ERC721 logic:
 *
 *      - Ability to mint NFTs via the provided `mint` function.
 *
 *      - Contract metadata for royalty support on platforms such as OpenSea that use 
 *        off-chain information to distribute roaylties.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability for fetching NFT data.
 *
 *      - EIP 2981 compliance for outright royalty support on NFT marketplaces.
 */

contract ERC721Base is 
    ERC721,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty
{
    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    uint256 public nextTokenIdToMint;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenURI The metadata of the NFT to mint.
     *  @param _data     Additional data to pass along during the minting of the NFT.
     */
    function mint(address _to, string memory _tokenURI, bytes memory _data) public virtual {
        require(_canMint(), "Not authorized to mint.");
        
        uint256 _id = _getNextTokenIdToMint();

        _safeMint(_to, _id, _data);
        _setTokenURI(_id, _tokenURI);
    }

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {

        address ownerOfToken = ownerOf(_tokenId);
        bool isApprovedOrOwner = (msg.sender ==  ownerOfToken ||
            isApprovedForAll[ownerOfToken][msg.sender] ||
            getApproved[_tokenId] == msg.sender);

        require(isApprovedOrOwner, "Caller not owner nor approved.");
        _burn(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the tokenId to assign to an NFT at the time of the NFT's minting.
    function _getNextTokenIdToMint() internal virtual returns (uint256) {
        uint256 id = nextTokenIdToMint;
        uint256 startId = _startTokenId();

        if(id < startId) {
            id = startId;
        }

        nextTokenIdToMint = id + 1;

        return id;
    }

    /// @dev The tokenId assigned to the first NFT minted. TokenIds are issued / minted in a serial order e.g. 0,1,2... so on.
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /// @dev Sets the metadata URI of the NFT at the given tokenId.
    function _setTokenURI(uint256 tokenId, string memory _uri) internal virtual {
        _tokenURI[tokenId] = _uri;
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
