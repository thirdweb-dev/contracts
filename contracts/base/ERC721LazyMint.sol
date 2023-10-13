// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721A } from "../eip/ERC721AVirtualApprove.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/LazyMint.sol";
import "../extension/interface/IClaimableERC721.sol";

import "../lib/TWStrings.sol";
import "../external-deps/openzeppelin/security/ReentrancyGuard.sol";

/**
 *      BASE:      ERC721A
 *      EXTENSION: LazyMint
 *
 *  The `ERC721LazyMint` smart contract implements the ERC721 NFT standard, along with the ERC721A optimization to the standard.
 *  It includes the following additions to standard ERC721 logic:
 *
 *      - Lazy minting
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
 *  'Lazy minting' means defining the metadata of NFTs without minting it to an address. Regular 'minting'
 *  of  NFTs means actually assigning an owner to an NFT.
 *
 *  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,
 *  without paying the gas cost for actually minting the NFTs.
 */

contract ERC721LazyMint is
    ERC721A,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty,
    BatchMintMetadata,
    LazyMint,
    IClaimableERC721,
    ReentrancyGuard
{
    using TWStrings for uint256;

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
     */
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721A(_name, _symbol) {
        _setupOwner(_defaultAdmin);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
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

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            Claiming logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an address claim multiple lazy minted NFTs at once to a recipient.
     *                   This function prevents any reentrant calls, and is not allowed to be overridden.
     *
     *  @dev             Contract creators should override `verifyClaim` and `transferTokensOnClaim`
     *                   functions to create custom logic for verification and claiming,
     *                   for e.g. price collection, allowlist, max quantity, etc.
     *                   The logic in `verifyClaim` determines whether the caller is authorized to mint NFTs.
     *                   The logic in `transferTokensOnClaim` does actual minting of tokens,
     *                   can also be used to apply other state changes.
     *
     *  @param _receiver  The recipient of the NFT to mint.
     *  @param _quantity  The number of NFTs to mint.
     */
    function claim(address _receiver, uint256 _quantity) public payable virtual nonReentrant {
        require(_currentIndex + _quantity <= nextTokenIdToLazyMint, "Not enough lazy minted tokens.");
        verifyClaim(msg.sender, _quantity); // Add your claim verification logic by overriding this function.

        uint256 startTokenId = _transferTokensOnClaim(_receiver, _quantity); // Mints tokens. Apply any state updates by overriding this function.
        emit TokensClaimed(msg.sender, _receiver, startTokenId, _quantity);
    }

    /**
     *  @notice          Checks a request to claim NFTs against a custom condition.
     *
     *  @dev             Override this function to add logic for claim verification, based on conditions
     *                   such as allowlist, price, max quantity etc.
     *
     *  @param _claimer   Caller of the claim function.
     *  @param _quantity  The number of NFTs being claimed.
     */
    function verifyClaim(address _claimer, uint256 _quantity) public view virtual {}

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @notice The tokenId assigned to the next new NFT to be claimed.
    function nextTokenIdToClaim() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /*//////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Mints tokens to receiver on claim.
     *                   Any state changes related to `claim` must be applied
     *                   here by overriding this function.
     *
     *  @dev             Override this function to add logic for state updation.
     *                   When overriding, apply any state changes before `_safeMint`.
     *
     * @param _receiver The recipient of the NFT to mint.
     * @param _quantity The number of NFTs to mint.
     *
     * @return startTokenId The tokenId of the first NFT minted.
     */
    function _transferTokensOnClaim(address _receiver, uint256 _quantity)
        internal
        virtual
        returns (uint256 startTokenId)
    {
        startTokenId = _currentIndex;
        _safeMint(_receiver, _quantity);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
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
}
