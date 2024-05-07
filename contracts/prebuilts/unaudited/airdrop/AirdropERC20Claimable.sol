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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../../extension/Multicall.sol";

//  ==========  Internal imports    ==========

import "../../interface/airdrop/IAirdropERC20Claimable.sol";

//  ==========  Features    ==========

import "../../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";
import "../../../lib/MerkleProof.sol";

contract AirdropERC20Claimable is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    Multicall,
    IAirdropERC20Claimable
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev address of token being airdropped.
    address public airdropTokenAddress;

    /// @dev address of owner of tokens being airdropped.
    address public tokenOwner;

    /// @dev number tokens available to claim.
    uint256 public availableAmount;

    /// @dev airdrop expiration timestamp.
    uint256 public expirationTimestamp;

    /// @dev claim limit for open/public claiming without allowlist.
    uint256 public openClaimLimitPerWallet;

    /// @dev merkle root of the allowlist of addresses eligible to claim.
    bytes32 public merkleRoot;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from address => total number of tokens a wallet has claimed.
    mapping(address => uint256) public supplyClaimedByWallet;

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
        uint256 _airdropAmount,
        uint256 _expirationTimestamp,
        uint256 _openClaimLimitPerWallet,
        bytes32 _merkleRoot
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        tokenOwner = _tokenOwner;
        airdropTokenAddress = _airdropTokenAddress;
        availableAmount = _airdropAmount;
        expirationTimestamp = _expirationTimestamp;
        openClaimLimitPerWallet = _openClaimLimitPerWallet;
        merkleRoot = _merkleRoot;
    }

    /*///////////////////////////////////////////////////////////////
                            Claim logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param _receiver                       The receiver of the NFTs to claim.
     *  @param _quantity                       The quantity of NFTs to claim.
     *  @param _proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param _proofMaxQuantityForWallet      The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address _receiver,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityForWallet
    ) external nonReentrant {
        address claimer = _msgSender();

        verifyClaim(claimer, _quantity, _proofs, _proofMaxQuantityForWallet);

        _transferClaimedTokens(_receiver, _quantity);

        emit TokensClaimed(_msgSender(), _receiver, _quantity);
    }

    /// @dev Checks a request to claim tokens against the active claim condition's criteria.
    function verifyClaim(
        address _claimer,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityForWallet
    ) public view {
        bool isOverride;

        /*
         * Here `isOverride` implies that if the merkle proof verification fails,
         * the claimer would claim through open claim limit instead of allowlisted limit.
         */
        if (merkleRoot != bytes32(0)) {
            (isOverride, ) = MerkleProof.verify(
                _proofs,
                merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityForWallet))
            );
        }

        uint256 supplyClaimedAlready = supplyClaimedByWallet[_claimer];

        require(_quantity > 0, "Claiming zero tokens");
        require(_quantity <= availableAmount, "exceeds available tokens.");

        uint256 expTimestamp = expirationTimestamp;
        require(expTimestamp == 0 || block.timestamp < expTimestamp, "airdrop expired.");

        uint256 claimLimitForWallet = isOverride ? _proofMaxQuantityForWallet : openClaimLimitPerWallet;
        require(_quantity + supplyClaimedAlready <= claimLimitForWallet, "invalid quantity.");
    }

    /// @dev Transfers the tokens being claimed.
    function _transferClaimedTokens(address _to, uint256 _quantityBeingClaimed) internal {
        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        supplyClaimedByWallet[_msgSender()] += _quantityBeingClaimed;
        availableAmount -= _quantityBeingClaimed;

        require(IERC20(airdropTokenAddress).transferFrom(tokenOwner, _to, _quantityBeingClaimed), "transfer failed");
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
