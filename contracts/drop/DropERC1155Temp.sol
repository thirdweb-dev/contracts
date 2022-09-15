// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

//  ==========  Internal imports    ==========

import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/PlatformFee.sol";
import "../extension/Royalty.sol";
import "../extension/PrimarySale.sol";
import "../extension/Ownable.sol";
import "../extension/DelayedReveal.sol";
import "../extension/LazyMint.sol";
import "../extension/PermissionsEnumerable.sol";
import "../extension/Drop1155.sol";

contract DropERC721Temp is
    Initializable,
    ContractMetadata,
    PlatformFee,
    Royalty,
    PrimarySale,
    Ownable,
    DelayedReveal,
    LazyMint,
    PermissionsEnumerable,
    Drop1155,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC1155Upgradeable
{
    using StringsUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private transferRole;
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private minterRole;

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public maxTotalSupply;

    /*///////////////////////////////////////////////////////////////
                               Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}
    
    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");

        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155_init_unchained("");

        // Initialize this contract's state.
        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        transferRole = _transferRole;
        minterRole = _minterRole;
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the uri for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory) {
        (uint256 batchId, ) = getBatchId(_tokenId);
        string memory batchUri = getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function contractType() external pure returns (bytes32) {
        return bytes32("DropERC1155");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(3);
    }

    /*///////////////////////////////////////////////////////////////
                    Lazy minting + delayed-reveal logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override onlyRole(minterRole) returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key)
        external
        onlyRole(minterRole)
        returns (string memory revealedURI)
    {
        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        // if (_tokenId >= nextTokenIdToLazyMint) {
        //     revert("Not enough minted tokens");
        // }
        require(
            maxTotalSupply[_tokenId] == 0 || totalSupply[_tokenId] + _quantity <= maxTotalSupply[_tokenId],
            "exceed max total supply"
        );
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("!Price");
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice - platformFees);
    }

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(address _to, uint256 _tokenId, uint256 _quantityBeingClaimed)
        internal
        override
    {
        _mint(_to, _tokenId, _quantityBeingClaimed, "");
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint;
    }

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
        if (!hasRole(transferRole, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(transferRole, from) || hasRole(transferRole, to), "restricted to TRANSFER_ROLE holders.");
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

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
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
