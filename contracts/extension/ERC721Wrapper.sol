// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  External imports    ==========

import "../eip/interface/IERC721.sol";
import "../eip/interface/IERC721Metadata.sol";

//  ==========  Internal imports    ==========

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/PermissionsEnumerable.sol";
import "../extension/interface/IERC721Wrapper.sol";

import "../lib/TWStrings.sol";

/**
 *  @title   ERC721Wrapper
 *  @notice  `ERC721Wrapper` contract extension allows exchange of existing ERC721 tokens with a
 *           new token with same metadata.
 */

abstract contract ERC721Wrapper is
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty,
    BatchMintMetadata,
    PermissionsEnumerable,
    IERC721Wrapper
{
    using TWStrings for uint256;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    address public currentTokenAddress;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => string) private tokenURIs;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _currentTokenAddress,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) {
        name = _name;
        symbol = _symbol;
        currentTokenAddress = _currentTokenAddress;
        _setupOwner(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /*//////////////////////////////////////////////////////////////
                          ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {
        return tokenURIs[_tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                            Exchange logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Lets an owner or approved operator exchange the NFT of the given tokenId.
     *
     *  @param _tokenId The tokenId of the NFT to exchange.
     */
    function exchange(uint256 _tokenId) external virtual override {
        require(IERC721(currentTokenAddress).ownerOf(_tokenId) != address(0), "invalid tokenId");
        string memory _tokenURI = IERC721Metadata(currentTokenAddress).tokenURI(_tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        _burnCurrentToken(_tokenId);
        _issueNewToken(_tokenId);
    }

    function _burnCurrentToken(uint256 _tokenId) internal virtual;

    function _issueNewToken(uint256 _tokenId) internal virtual;

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(bytes(tokenURIs[_tokenId]).length == 0, "URI already set");
        tokenURIs[_tokenId] = _tokenURI;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
