// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

//  ==========  Internal imports    ==========

import "./interfaces/IMultiwrap.sol";
import "./lib/CurrencyTransferLib.sol";
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

contract Multiwrap is
    IMultiwrap,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ERC721Upgradeable
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("Multiwrap");
    uint256 private constant VERSION = 1;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can wrap tokens, when wrapping is restricted.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /// @dev The next token ID of the NFT to mint.
    uint256 public nextTokenIdToMint;

    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint128 private royaltyBps;

    /// @dev Max bps in the thirdweb system.
    uint128 private constant MAX_BPS = 10_000;

    /// @dev Contract level metadata.
    string public contractURI;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from tokenId of wrapped NFT => royalty recipient and bps for token.
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /// @dev Mapping from tokenId of wrapped NFT => uri for the token.
    mapping(uint256 => string) private uri;

    /// @dev Mapping from tokenId of wrapped NFT => wrapped contents of the token.
    mapping(uint256 => WrappedContents) private wrappedContents;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) initializer {
        nativeTokenWrapper = _nativeTokenWrapper;
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);

        // Initialize this contract's state.
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);
        contractURI = _contractURI;
        _owner = _defaultAdmin;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyMinter() {
        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(MINTER_ROLE, address(0))) {
            require(hasRole(MINTER_ROLE, _msgSender()) , "restricted to MINTER_ROLE holders.");
        }

        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return uri[_tokenId];
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155ReceiverUpgradeable, ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

    /// @dev Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                    Wrapping / Unwrapping logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Wrap multiple ERC1155, ERC721, ERC20 tokens into a single wrapped NFT.
    function wrap(
        Token[] calldata _wrappedContents,
        string calldata _uriForWrappedToken,
        address _recipient
    ) external payable nonReentrant onlyMinter returns (uint256 tokenId) {
        tokenId = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        for(uint256 i = 0; i < _wrappedContents.length; i += 1) {
            wrappedContents[tokenId].token[i] = _wrappedContents[i];
        }
        wrappedContents[tokenId].count = _wrappedContents.length;

        uri[tokenId] = _uriForWrappedToken;

        _safeMint(_recipient, tokenId);

        transferTokenBatch(_msgSender(), address(this), _wrappedContents);

        emit TokensWrapped(_msgSender(), _recipient, tokenId, _wrappedContents);
    }

    /// @dev Unwrap a wrapped NFT to retrieve underlying ERC1155, ERC721, ERC20 tokens.
    function unwrap(
        uint256 _tokenId,
        address _recipient
    ) external nonReentrant {
        require(_tokenId < nextTokenIdToMint, "invalid tokenId");
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "unapproved called");

        _burn(_tokenId);

        uint256 count = wrappedContents[_tokenId].count;
        Token[] memory tokensUnwrapped = new Token[](count);

        for(uint256 i = 0; i < count; i += 1) {
            tokensUnwrapped[i] = wrappedContents[_tokenId].token[i];
            transferToken(address(this), _recipient, tokensUnwrapped[i]);
        }

        delete wrappedContents[_tokenId];

        emit TokensUnwrapped(_msgSender(), _recipient, _tokenId, tokensUnwrapped);
    }

    /// @dev Transfers an arbitrary ERC20 / ERC721 / ERC1155 token.
    function transferToken(address _from, address _to, Token memory _token) internal {
        if(_token.tokenType == TokenType.ERC20) {
            CurrencyTransferLib.transferCurrencyWithWrapperAndBalanceCheck(
                _token.assetContract,
                _from,
                _to,
                _token.amount,
                nativeTokenWrapper
            );
        } else if(_token.tokenType == TokenType.ERC721) {
            IERC721Upgradeable(_token.assetContract).safeTransferFrom(_from, _to, _token.tokenId);
        } else if(_token.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(_token.assetContract).safeTransferFrom(_from, _to, _token.tokenId, _token.amount, "");
        }
    }

    /// @dev Transfers multiple arbitrary ERC20 / ERC721 / ERC1155 tokens.
    function transferTokenBatch(address _from, address _to, Token[] memory _tokens) internal {
        for(uint256 i = 0; i < _tokens.length; i += 1) {
            transferToken(_from, _to, _tokens[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the platform fee bps and recipient.
    function getDefaultRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_royaltyBps <= MAX_BPS, "exceed royalty bps");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bps <= MAX_BPS, "exceed royalty bps");

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        emit OwnerUpdated(_owner, _newOwner);
        _owner = _newOwner;
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders.");
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
