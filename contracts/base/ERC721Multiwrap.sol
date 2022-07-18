// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./ERC721Base.sol";

import { PermissionsEnumerable } from "../extension/PermissionsEnumerable.sol";
import { TokenStore, ERC1155Receiver, IERC1155Receiver } from "../extension/TokenStore.sol";
import { Multicall } from "../extension/Multicall.sol";


contract ERC721Multiwrap is Multicall, TokenStore, PermissionsEnumerable, ERC721Base {

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _nativeTokenWrapper
    )
        ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps)
        TokenStore(_nativeTokenWrapper)
    {}

    /*///////////////////////////////////////////////////////////////
                    Wrapping / Unwrapping logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Wrap multiple ERC1155, ERC721, ERC20 tokens into a single wrapped NFT.
    function wrap(
        Token[] calldata _tokensToWrap,
        string calldata _uriForWrappedToken,
        address _recipient
    ) external payable nonReentrant onlyRoleWithSwitch(MINTER_ROLE) returns (uint256 tokenId) {
        if (!hasRole(ASSET_ROLE, address(0))) {
            for (uint256 i = 0; i < _tokensToWrap.length; i += 1) {
                _checkRole(ASSET_ROLE, _tokensToWrap[i].assetContract);
            }
        }

        tokenId = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        _storeTokens(_msgSender(), _tokensToWrap, _uriForWrappedToken, tokenId);

        _safeMint(_recipient, tokenId);

        emit TokensWrapped(_msgSender(), _recipient, tokenId, _tokensToWrap);
    }

    /// @dev Unwrap a wrapped NFT to retrieve underlying ERC1155, ERC721, ERC20 tokens.
    function unwrap(uint256 _tokenId, address _recipient) external nonReentrant onlyRoleWithSwitch(UNWRAP_ROLE) {
        require(_tokenId < nextTokenIdToMint, "wrapped NFT DNE.");
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "caller not approved for unwrapping.");

        _burn(_tokenId);
        _releaseTokens(_recipient, _tokenId);

        emit TokensUnwrapped(_msgSender(), _recipient, _tokenId);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, ERC721Base)
        returns (bool)
    {
        return
            ERC721Base.supportsInterface(interfaceId) ||
            interfaceId == type(IERC1155Receiver).interfaceId;

    }
}