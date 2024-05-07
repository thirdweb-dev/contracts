// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721A, Context } from "../eip/ERC721AVirtualApprove.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/PrimarySale.sol";
import "../extension/DropSinglePhase.sol";
import "../extension/LazyMint.sol";
import "../extension/DelayedReveal.sol";

import "../lib/Strings.sol";
import { CurrencyTransferLib } from "../lib/CurrencyTransferLib.sol";

/**
 *      BASE:      ERC721A
 *      EXTENSION: DropSinglePhase
 *
 *  The `ERC721Drop` contract implements the ERC721 NFT standard, along with the ERC721A optimization to the standard.
 *  It includes the following additions to standard ERC721 logic:
 *
 *      - Contract metadata for royalty support on platforms such as OpenSea that use
 *        off-chain information to distribute roaylties.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2981 compliance for royalty support on NFT marketplaces.
 *
 *  The `drop` mechanism in the `DropSinglePhase` extension is a distribution mechanism for lazy minted tokens. It lets
 *  you set restrictions such as a price to charge, an allowlist etc. when an address atttempts to mint lazy minted tokens.
 *
 *  The `ERC721Drop` contract lets you lazy mint tokens, and distribute those lazy minted tokens via the drop mechanism.
 */

contract ERC721Drop is
    ERC721A,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty,
    BatchMintMetadata,
    PrimarySale,
    LazyMint,
    DelayedReveal,
    DropSinglePhase
{
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
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
     * @param _primarySaleRecipient The address to receive primary sale value.
     */
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    ) ERC721A(_name, _symbol) {
        _setupOwner(_defaultAdmin);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_primarySaleRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*///////////////////////////////////////////////////////////////
                    Overriden ERC 721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        (uint256 batchId, ) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Overriden lazy minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The placeholder base URI for the 'n' number of NFTs being lazy minted, where the
     *                           metadata for each of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _data             The encrypted base URI + provenance hash for the batch of NFTs being lazy minted.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public virtual override returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        return LazyMint.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @notice The tokenId assigned to the next new NFT to be claimed.
    function nextTokenIdToClaim() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /*///////////////////////////////////////////////////////////////
                        Delayed reveal logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice       Lets an authorized address reveal a batch of delayed reveal NFTs.
     *
     *  @param _index The ID for the batch of delayed-reveal NFTs to reveal.
     *  @param _key   The key with which the base URI for the relevant batch of NFTs was encrypted.
     */
    function reveal(uint256 _index, bytes calldata _key) public virtual override returns (string memory revealedURI) {
        require(_canReveal(), "Not authorized");

        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*//////////////////////////////////////////////////////////////
                        Minting/burning logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Runs before every `claim` function call.
     *
     * @param _quantity The quantity of NFTs being claimed.
     */
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view virtual override {
        if (_currentIndex + _quantity > nextTokenIdToLazyMint) {
            revert("Not enough minted tokens");
        }
    }

    /**
     * @dev Collects and distributes the primary sale value of NFTs being claimed.
     *
     * @param _primarySaleRecipient The address to receive the primary sale value.
     * @param _quantityToClaim      The quantity of NFTs being claimed.
     * @param _currency             The currency in which the NFTs are being claimed.
     * @param _pricePerToken        The price per token in the given currency.
     */
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {
        if (_pricePerToken == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "Invalid msg value");

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;
        CurrencyTransferLib.transferCurrency(_currency, msg.sender, saleRecipient, totalPrice);
    }

    /**
     * @dev Transfers the NFTs being claimed.
     *
     * @param _to                    The address to which the NFTs are being transferred.
     * @param _quantityBeingClaimed  The quantity of NFTs being claimed.
     */
    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal virtual override returns (uint256 startTokenId) {
        startTokenId = _currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Checks whether NFTs can be revealed in the given execution context.
    function _canReveal() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _dropMsgSender() internal view virtual override returns (address) {
        return msg.sender;
    }

    /// @notice Returns the sender in the given execution context.
    function _msgSender() internal view override(Multicall, Context) returns (address) {
        return msg.sender;
    }
}
