// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  External imports    ==========

import "../eip/interface/IERC1155.sol";
import "../eip/interface/IERC1155Metadata.sol";

//  ==========  Internal imports    ==========

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/PermissionsEnumerable.sol";
import "../extension/interface/IERC1155Wrapper.sol";

import "../lib/TWStrings.sol";

/**
 *  @title   ERC1155Wrapper
 *  @notice  `ERC1155Wrapper` contract extension allows exchange of existing ERC1155 tokens with 
 *           new tokens with same metadata.
 */

abstract contract ERC1155Wrapper is 
    ContractMetadata, 
    Multicall, 
    Ownable, 
    Royalty, 
    BatchMintMetadata, 
    PermissionsEnumerable,
    IERC1155Wrapper
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

    mapping(uint256 => string) private _uri;

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
                          ERC1155 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function uri(uint256 _tokenId) public view virtual returns (string memory) {
        return _uri[_tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                            Exchange logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Lets an owner or approved operator exchange the NFT of the given tokenId.
     *
     *  @param _tokenId The tokenId of the NFT to exchange.
     */
    function exchange(uint256 _tokenId, uint256 _amount) external virtual override {
        string memory _tokenURI = IERC1155Metadata(currentTokenAddress).uri(_tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        // how will this work for ERC1155 -- same tokens on multiple contracts?
        _burnCurrentToken(_tokenId, _amount);
        _issueNewToken(_tokenId, _amount);
    }

    function _burnCurrentToken(uint256 _tokenId, uint256 _amount) internal virtual;

    function _issueNewToken(uint256 _tokenId, uint256 _amount) internal virtual;

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(bytes(_uri[_tokenId]).length == 0, "URI already set");
        _uri[_tokenId] = _tokenURI;
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
