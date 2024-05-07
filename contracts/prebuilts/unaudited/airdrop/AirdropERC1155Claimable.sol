// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  External imports    ==========
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { Multicall } from "../../../extension/Multicall.sol";

//  ==========  Internal imports    ==========

import "../../interface/airdrop/IAirdropERC1155Claimable.sol";

//  ==========  Features    ==========

import "../../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";
import "../../../lib/MerkleProof.sol";

contract AirdropERC1155Claimable is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    Multicall,
    IAirdropERC1155Claimable
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev address of token being airdropped.
    address public airdropTokenAddress;

    /// @dev address of owner of tokens being airdropped.
    address public tokenOwner;

    /// @dev list of tokens to airdrop.
    uint256[] public tokenIds;

    /// @dev airdrop expiration timestamp.
    uint256 public expirationTimestamp;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from tokenId and claimer address to total number of tokens claimed.
    mapping(uint256 => mapping(address => uint256)) public supplyClaimedByWallet;

    /// @dev claim limit for open/public claiming without allowlist.
    mapping(uint256 => uint256) public openClaimLimitPerWallet;

    /// @dev number tokens available to claim for a tokenId.
    mapping(uint256 => uint256) public availableAmount;

    /// @dev mapping of tokenId to merkle root of the allowlist of addresses eligible to claim.
    mapping(uint256 => bytes32) public merkleRoot;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address[] memory _trustedForwarders,
        address _tokenOwner,
        address _airdropTokenAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _availableAmounts,
        uint256 _expirationTimestamp,
        uint256[] memory _openClaimLimitPerWallet,
        bytes32[] memory _merkleRoot
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        tokenOwner = _tokenOwner;
        airdropTokenAddress = _airdropTokenAddress;
        tokenIds = _tokenIds;
        expirationTimestamp = _expirationTimestamp;

        require(
            _openClaimLimitPerWallet.length == _tokenIds.length &&
                _merkleRoot.length == _tokenIds.length &&
                _availableAmounts.length == _tokenIds.length,
            "length mismatch."
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            merkleRoot[_tokenIds[i]] = _merkleRoot[i];
            openClaimLimitPerWallet[_tokenIds[i]] = _openClaimLimitPerWallet[i];
            availableAmount[_tokenIds[i]] = _availableAmounts[i];
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Claim logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Lets an account claim a given quantity of ERC1155 tokens.
     *
     *  @param _receiver                      The receiver of the tokens to claim.
     *  @param _quantity                      The quantity of tokens to claim.
     *  @param _tokenId                       Token Id to claim.
     *  @param _proofs                        The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param _proofMaxQuantityForWallet     The maximum number of tokens an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address _receiver,
        uint256 _quantity,
        uint256 _tokenId,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityForWallet
    ) external nonReentrant {
        address claimer = _msgSender();

        verifyClaim(claimer, _quantity, _tokenId, _proofs, _proofMaxQuantityForWallet);

        _transferClaimedTokens(_receiver, _quantity, _tokenId);

        emit TokensClaimed(_msgSender(), _receiver, _tokenId, _quantity);
    }

    /// @dev Transfers the tokens being claimed.
    function _transferClaimedTokens(address _to, uint256 _quantityBeingClaimed, uint256 _tokenId) internal {
        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        supplyClaimedByWallet[_tokenId][_msgSender()] += _quantityBeingClaimed;
        availableAmount[_tokenId] -= _quantityBeingClaimed;

        IERC1155(airdropTokenAddress).safeTransferFrom(tokenOwner, _to, _tokenId, _quantityBeingClaimed, "");
    }

    /// @dev Checks a request to claim tokens against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        uint256 _tokenId,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityForWallet
    ) public view {
        bool isOverride;

        /*
         * Here `isOverride` implies that if the merkle proof verification fails,
         * the claimer would claim through open claim limit instead of allowlisted limit.
         */
        bytes32 mroot = merkleRoot[_tokenId];
        if (mroot != bytes32(0)) {
            (isOverride, ) = MerkleProof.verify(
                _proofs,
                mroot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityForWallet))
            );
        }

        uint256 supplyClaimedAlready = supplyClaimedByWallet[_tokenId][_claimer];

        require(_quantity > 0, "Claiming zero tokens");
        require(_quantity <= availableAmount[_tokenId], "exceeds available tokens.");

        uint256 expTimestamp = expirationTimestamp;
        require(expTimestamp == 0 || block.timestamp < expTimestamp, "airdrop expired.");

        uint256 claimLimitForWallet = isOverride ? _proofMaxQuantityForWallet : openClaimLimitPerWallet[_tokenId];
        require(_quantity + supplyClaimedAlready <= claimLimitForWallet, "invalid quantity.");
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, Multicall)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }
}
