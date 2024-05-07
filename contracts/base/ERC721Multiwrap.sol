// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721A, Context } from "../eip/ERC721AVirtualApprove.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/SoulboundERC721A.sol";
import "../extension/TokenStore.sol";
import "../extension/Multicall.sol";
import { ReentrancyGuard } from "../extension/upgradeable/ReentrancyGuard.sol";

/**
 *      BASE:      ERC721Base
 *      EXTENSION: TokenStore, SoulboundERC721A
 *
 *  The `ERC721Multiwrap` contract uses the `ERC721Base` contract, along with the `TokenStore` and
 *   `SoulboundERC721A` extension.
 *
 *  The `ERC721Multiwrap` contract lets you wrap arbitrary ERC20, ERC721 and ERC1155 tokens you own
 *  into a single wrapped token / NFT.
 *
 *  The `SoulboundERC721A` extension lets you make your NFTs 'soulbound' i.e. non-transferrable.
 *
 */

contract ERC721Multiwrap is
    Multicall,
    TokenStore,
    SoulboundERC721A,
    ERC721A,
    ContractMetadata,
    Ownable,
    Royalty,
    ReentrancyGuard
{
    /*//////////////////////////////////////////////////////////////
                    Permission control roles
    //////////////////////////////////////////////////////////////*/

    /// @dev Only MINTER_ROLE holders can wrap tokens, when wrapping is restricted.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only UNWRAP_ROLE holders can unwrap tokens, when unwrapping is restricted.
    bytes32 private constant UNWRAP_ROLE = keccak256("UNWRAP_ROLE");
    /// @dev Only assets with ASSET_ROLE can be wrapped, when wrapping is restricted to particular assets.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(
        address indexed wrapper,
        address indexed recipientOfWrappedToken,
        uint256 indexed tokenIdOfWrappedToken,
        Token[] wrappedContents
    );

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed unwrapper,
        address indexed recipientOfWrappedContents,
        uint256 indexed tokenIdOfWrappedToken
    );

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks whether the caller holds `role`, when restrictions for `role` are switched on.
    modifier onlyRoleWithSwitch(bytes32 role) {
        _checkRoleWithSwitch(role, msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract during construction.
     *
     * @param _defaultAdmin     The default admin of the contract.
     * @param _name             The name of the contract.
     * @param _symbol           The symbol of the contract.
     * @param _royaltyRecipient The address to receive royalties.
     * @param _royaltyBps       The royalty basis points to be charged. Max = 10000 (10000 = 100%, 1000 = 10%)
     * @param _nativeTokenWrapper The address of the ERC20 wrapper for the native token.
     */
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _nativeTokenWrapper
    ) ERC721A(_name, _symbol) TokenStore(_nativeTokenWrapper) {
        _setupOwner(_defaultAdmin);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);

        _setupRole(ASSET_ROLE, address(0));
        _setupRole(UNWRAP_ROLE, address(0));

        restrictTransfers(false);
    }

    /*///////////////////////////////////////////////////////////////
                        Public gette functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Receiver, ERC721A, IERC165) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId || // ERC165 ID for ERC2981
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return getUriOfBundle(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                    Wrapping / Unwrapping logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Wrap multiple ERC1155, ERC721, ERC20 tokens into a single wrapped NFT.
     *
     *  @param _tokensToWrap    The tokens to wrap.
     *  @param _uriForWrappedToken The metadata URI for the wrapped NFT.
     *  @param _recipient          The recipient of the wrapped NFT.
     *
     *  @return tokenId The tokenId of the wrapped NFT minted.
     */
    function wrap(
        Token[] calldata _tokensToWrap,
        string calldata _uriForWrappedToken,
        address _recipient
    ) public payable virtual onlyRoleWithSwitch(MINTER_ROLE) nonReentrant returns (uint256 tokenId) {
        if (!hasRole(ASSET_ROLE, address(0))) {
            for (uint256 i = 0; i < _tokensToWrap.length; i += 1) {
                _checkRole(ASSET_ROLE, _tokensToWrap[i].assetContract);
            }
        }

        tokenId = nextTokenIdToMint();

        _storeTokens(msg.sender, _tokensToWrap, _uriForWrappedToken, tokenId);

        _safeMint(_recipient, 1);

        emit TokensWrapped(msg.sender, _recipient, tokenId, _tokensToWrap);
    }

    /**
     *  @notice Unwrap a wrapped NFT to retrieve underlying ERC1155, ERC721, ERC20 tokens.
     *
     *  @param _tokenId   The token Id of the wrapped NFT to unwrap.
     *  @param _recipient The recipient of the underlying ERC1155, ERC721, ERC20 tokens of the wrapped NFT.
     */
    function unwrap(uint256 _tokenId, address _recipient) public virtual onlyRoleWithSwitch(UNWRAP_ROLE) nonReentrant {
        require(_tokenId < nextTokenIdToMint(), "wrapped NFT DNE.");
        require(isApprovedOrOwner(msg.sender, _tokenId), "caller not approved for unwrapping.");

        _burn(_tokenId);
        _releaseTokens(_recipient, _tokenId);

        emit TokensUnwrapped(msg.sender, _recipient, _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        Public getters
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @notice Returns whether a given address is the owner, or approved to transfer an NFT.
     *
     * @param _operator The address to check.
     * @param _tokenId The tokenId to check.
     *
     * @return isApprovedOrOwnerOf Whether `_operator` is approved to transfer `_tokenId`.
     */
    function isApprovedOrOwner(
        address _operator,
        uint256 _tokenId
    ) public view virtual returns (bool isApprovedOrOwnerOf) {
        address owner = ownerOf(_tokenId);
        isApprovedOrOwnerOf = (_operator == owner ||
            isApprovedForAll(owner, _operator) ||
            getApproved(_tokenId) == _operator);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * @inheritdoc ERC721A
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, SoulboundERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        SoulboundERC721A._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Returns whether transfers can be restricted in a given execution context.
    function _canRestrictTransfers() internal view virtual override returns (bool) {
        return msg.sender == owner();
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

    /// @notice Returns the sender in the given execution context.
    function _msgSender() internal view override(Multicall, Context) returns (address) {
        return msg.sender;
    }
}
