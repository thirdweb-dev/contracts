// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC1155 } from "../eip/ERC1155.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/LazyMint.sol";
import "../extension/interface/IClaimableERC1155.sol";
import "../extension/DefaultOperatorFilterer.sol";

import "../lib/TWStrings.sol";
import "../openzeppelin-presets/security/ReentrancyGuard.sol";

/**
 *      BASE:      ERC1155Base
 *      EXTENSION: LazyMint
 *
 *  The `ERC1155LazyMint` smart contract implements the ERC1155 NFT standard.
 *  It includes the following additions to standard ERC1155 logic:
 *
 *      - Lazy minting
 *
 *      - Ability to mint NFTs via the provided `mintTo` and `batchMintTo` functions.
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
 *
 *  The `ERC1155LazyMint` contract uses the `LazyMint` extension.
 *
 *  'Lazy minting' means defining the metadata of NFTs without minting it to an address. Regular 'minting'
 *  of  NFTs means actually assigning an owner to an NFT.
 *
 *  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,
 *  without paying the gas cost for actually minting the NFTs.
 *
 */

contract ERC1155LazyMint is
    ERC1155,
    ContractMetadata,
    Ownable,
    Royalty,
    Multicall,
    BatchMintMetadata,
    LazyMint,
    IClaimableERC1155,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the total supply of NFTs of a given tokenId
     *  @dev Mapping from tokenId => total circulating supply of NFTs of that tokenId.
     */
    mapping(uint256 => uint256) public totalSupply;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155(_name, _symbol) {
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setOperatorRestriction(true);
    }

    /*//////////////////////////////////////////////////////////////
                    Overriden metadata logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the metadata URI for the given tokenId.
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an address claim multiple lazy minted NFTs at once to a recipient.
     *                   This function prevents any reentrant calls, and is not allowed to be overridden.
     *
     *                   Contract creators should override `verifyClaim` and `transferTokensOnClaim`
     *                   functions to create custom logic for verification and claiming,
     *                   for e.g. price collection, allowlist, max quantity, etc.
     *
     *  @dev             The logic in `verifyClaim` determines whether the caller is authorized to mint NFTs.
     *                   The logic in `transferTokensOnClaim` does actual minting of tokens,
     *                   can also be used to apply other state changes.
     *
     *  @param _receiver  The recipient of the tokens to mint.
     *  @param _tokenId   The tokenId of the lazy minted NFT to mint.
     *  @param _quantity  The number of tokens to mint.
     */
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) public payable nonReentrant {
        require(_tokenId < nextTokenIdToMint(), "invalid id");
        verifyClaim(msg.sender, _tokenId, _quantity); // Add your claim verification logic by overriding this function.

        _transferTokensOnClaim(_receiver, _tokenId, _quantity); // Mints tokens. Apply any state updates by overriding this function.
        emit TokensClaimed(msg.sender, _receiver, _tokenId, _quantity);
    }

    /**
     *  @notice          Override this function to add logic for claim verification, based on conditions
     *                   such as allowlist, price, max quantity etc.
     *
     *  @dev             Checks a request to claim NFTs against a custom condition.
     *
     *  @param _claimer   Caller of the claim function.
     *  @param _tokenId   The tokenId of the lazy minted NFT to mint.
     *  @param _quantity  The number of NFTs being claimed.
     */
    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view virtual {}

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenId.
     *
     *  @param _owner   The owner of the NFT to burn.
     *  @param _tokenId The tokenId of the NFT to burn.
     *  @param _amount  The amount of the NFT to burn.
     */
    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external virtual {
        address caller = msg.sender;

        require(caller == _owner || isApprovedForAll[_owner][caller], "Unapproved caller");
        require(balanceOf[_owner][_tokenId] >= _amount, "Not enough tokens owned");

        _burn(_owner, _tokenId, _amount);
    }

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenIds.
     *
     *  @param _owner    The owner of the NFTs to burn.
     *  @param _tokenIds The tokenIds of the NFTs to burn.
     *  @param _amounts  The amounts of the NFTs to burn.
     */
    function burnBatch(
        address _owner,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external virtual {
        address caller = msg.sender;

        require(caller == _owner || isApprovedForAll[_owner][caller], "Unapproved caller");
        require(_tokenIds.length == _amounts.length, "Length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(balanceOf[_owner][_tokenIds[i]] >= _amounts[i], "Not enough tokens owned");
        }

        _burnBatch(_owner, _tokenIds, _amounts);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether this contract supports the given interface.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*//////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC-1155 overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {ERC1155-setApprovalForAll}
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
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
     *                   When overriding, apply any state changes before `_mint`.
     */
    function _transferTokensOnClaim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity
    ) internal virtual {
        _mint(_receiver, _tokenId, _quantity, "");
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

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Runs before every token transfer / mint / burn.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

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
}
