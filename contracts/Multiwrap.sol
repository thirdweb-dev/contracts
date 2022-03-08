// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Base
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

// Interfaces
import "./interfaces/IMultiwrap.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

// Access Control + security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

// Meta transactions
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Helpers
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";
import "./lib/MultiTokenTransferLib.sol";

/**
 *      - Wrap multiple ERC721 and ERC20 tokens into 'n' shares (i.e. variable supply of 1 ERC 1155 token)
 */

contract Multiwrap is
    IMultiwrap,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155Upgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("Multiwrap");
    uint256 private constant VERSION = 1;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The next token ID of the NFT to mint.
    uint256 public nextTokenIdToMint;

    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint128 private royaltyBps;

    /// @dev Max bps in the thirdweb system
    uint128 private constant MAX_BPS = 10_000;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /// @dev Token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalShares;

    /// @dev Mapping from tokenId => uri for tokenId
    mapping(uint256 => string) private uriForShares;

    /// @dev Mapping from tokenId => wrapped contents of the token.
    mapping(uint256 => MultiTokenTransferLib.MultiToken) private wrappedContents;

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
        __ERC1155_init("");

        // Initialize this contract's state.
        name = _name;
        symbol = _symbol;
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);
        contractURI = _contractURI;

        _owner = _defaultAdmin;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
    }

    ///     =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev See ERC1155 - returns the metadata for a token.
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return uriForShares[_tokenId];
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    ///     =====   External functions  =====

    /// @dev Wrap multiple ERC1155, ERC721, ERC20 tokens into 'n' shares (i.e. variable supply of 1 ERC 1155 token)
    function wrap(
        MultiTokenTransferLib.MultiToken calldata _wrappedContents,
        uint256 _shares,
        string calldata _uriForShares
    ) external payable nonReentrant returns (uint256 tokenId) {
        tokenId = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        uriForShares[tokenId] = _uriForShares;
        wrappedContents[tokenId] = _wrappedContents;

        _mint(_msgSender(), tokenId, _shares, "");
        totalShares[tokenId] = _shares;

        MultiTokenTransferLib.transferAll(_msgSender(), address(this), _wrappedContents);

        emit TokensWrapped(_msgSender(), tokenId, _wrappedContents);
    }

    /// @dev Unwrap shares to retrieve underlying ERC1155, ERC721, ERC20 tokens.
    function unwrap(
        uint256 _tokenId,
        uint256 _amountToRedeem,
        address _sendTo
    ) external nonReentrant {
        require(_tokenId < nextTokenIdToMint, "invalid tokenId");
        require(balanceOf(_msgSender(), _tokenId) >= _amountToRedeem, "unwrapping more than owned");

        uint256 totalSharesOfToken = totalShares[_tokenId];
        bool isTotalRedemption = _amountToRedeem == totalSharesOfToken;

        MultiTokenTransferLib.MultiToken memory wrappedContents_ = wrappedContents[_tokenId];

        burn(_msgSender(), _tokenId, _amountToRedeem);

        if (totalSupply[_tokenId] == 0) {
            delete wrappedContents[_tokenId];
        }

        if (isTotalRedemption) {
            MultiTokenTransferLib.transferAll(address(this), _sendTo, wrappedContents_);
        } else {
            transfer20ByShares(address(this), _sendTo, wrappedContents_, _amountToRedeem, totalSharesOfToken);
        }

        emit TokensUnwrapped(_msgSender(), _sendTo, _tokenId, _amountToRedeem, wrappedContents_);
    }

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

    ///     =====   Internal functions  =====

    function transfer20ByShares(
        address _from,
        address _to,
        MultiTokenTransferLib.MultiToken memory _wrappedContents,
        uint256 _sharesToAccount,
        uint256 _totalShares
    ) internal {
        require(
            _wrappedContents.erc1155AssetContracts.length == 0 && _wrappedContents.erc721AssetContracts.length == 0,
            "cannot unwrap by shares"
        );

        bool isValidData = _wrappedContents.erc20AssetContracts.length == _wrappedContents.erc20AmountsToWrap.length;
        if (isValidData) {
            for (uint256 i = 0; i < _wrappedContents.erc20AssetContracts.length; i += 1) {
                isValidData = _wrappedContents.erc20AmountsToWrap[i] % _totalShares == 0;

                if (!isValidData) {
                    break;
                }
                uint256 tokensToIssue = (_wrappedContents.erc20AmountsToWrap[i] * _sharesToAccount) / _totalShares;

                CurrencyTransferLib.transferCurrency(
                    _wrappedContents.erc20AssetContracts[i],
                    _from,
                    _to,
                    tokensToIssue
                );
            }
        }
        require(isValidData, "invalid erc20 wrap");
    }

    /// @dev See EIP-2981
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

    ///     =====   Low-level overrides  =====

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders.");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable, IERC165Upgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
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
