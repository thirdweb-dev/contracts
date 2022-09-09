// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC1155Claimable.sol";

//  ==========  Features    ==========
import "../extension/Ownable.sol";

import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../lib/MerkleProof.sol";

contract AirdropERC1155Claimable is
    Initializable,
    Ownable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    IAirdropERC1155Claimable
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC1155Claimable");
    uint256 private constant VERSION = 1;

    /// @dev Owner of the airdrop contract.
    address private _owner;

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

    /// @dev general claim limit for a tokenId if claimer not in allowlist.
    mapping(uint256 => uint256) public maxWalletClaimCount;

    /// @dev number tokens available to claim for a tokenId.
    mapping(uint256 => uint256) public availableAmounts;

    /// @dev mapping of tokenId to merkle root of the allowlist of addresses eligible to claim.
    mapping(uint256 => bytes32) public merkleRoot;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        address[] memory _trustedForwarders,
        address _tokenOwner,
        address _airdropTokenAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _availableAmounts,
        uint256 _expirationTimestamp,
        uint256[] memory _maxWalletClaimCount,
        bytes32[] memory _merkleRoot
    ) external initializer {
        _setupOwner(_defaultAdmin);
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        tokenOwner = _tokenOwner;
        airdropTokenAddress = _airdropTokenAddress;
        tokenIds = _tokenIds;
        expirationTimestamp = _expirationTimestamp;

        require(
            _maxWalletClaimCount.length == _tokenIds.length &&
                _merkleRoot.length == _tokenIds.length &&
                _availableAmounts.length == _tokenIds.length,
            "length mismatch."
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            merkleRoot[_tokenIds[i]] = _merkleRoot[i];
            maxWalletClaimCount[_tokenIds[i]] = _maxWalletClaimCount[i];
            availableAmounts[_tokenIds[i]] = _availableAmounts[i];
        }
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
        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */

        // Verify inclusion in allowlist.
        verifyClaimMerkleProof(_msgSender(), _quantity, _tokenId, _proofs, _proofMaxQuantityForWallet);

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityForWallet value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        bool toVerifyMaxQuantityPerWallet = _proofMaxQuantityForWallet == 0 || merkleRoot[_tokenId] == bytes32(0);
        verifyClaim(_msgSender(), _quantity, _tokenId, toVerifyMaxQuantityPerWallet);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(_receiver, _quantity, _tokenId);

        emit TokensClaimed(_msgSender(), _receiver, _quantity);
    }

    /// @dev Transfers the tokens being claimed.
    function transferClaimedTokens(
        address _to,
        uint256 _quantityBeingClaimed,
        uint256 _tokenId
    ) internal {
        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        supplyClaimedByWallet[_tokenId][_msgSender()] += _quantityBeingClaimed;
        availableAmounts[_tokenId] -= _quantityBeingClaimed;

        IERC1155(airdropTokenAddress).safeTransferFrom(tokenOwner, _to, _tokenId, _quantityBeingClaimed, "");
    }

    /// @dev Checks a request to claim tokens against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        uint256 _tokenId,
        bool verifyMaxQuantityPerWallet
    ) public view {
        // If we're checking for an allowlist quantity restriction, ignore the general quantity restriction.
        require(
            _quantity > 0 &&
                (!verifyMaxQuantityPerWallet ||
                    maxWalletClaimCount[_tokenId] == 0 ||
                    _quantity + supplyClaimedByWallet[_tokenId][_claimer] <= maxWalletClaimCount[_tokenId]),
            "invalid quantity."
        );
        require(_quantity <= availableAmounts[_tokenId], "exceeds available tokens.");
        require(expirationTimestamp == 0 || block.timestamp < expirationTimestamp, "airdrop expired.");
    }

    /// @dev Checks whether a claimer meets the allowlist criteria.
    function verifyClaimMerkleProof(
        address _claimer,
        uint256 _quantity,
        uint256 _tokenId,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityForWallet
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        if (merkleRoot[_tokenId] != bytes32(0)) {
            uint256 _supplyClaimed = supplyClaimedByWallet[_tokenId][_claimer];

            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                merkleRoot[_tokenId],
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityForWallet))
            );
            require(validMerkleProof, "not in whitelist.");
            require(_supplyClaimed < _proofMaxQuantityForWallet, "proof claimed.");
            require(_quantity + _supplyClaimed <= _proofMaxQuantityForWallet, "invalid quantity.");
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return _msgSender() == owner();
    }

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
