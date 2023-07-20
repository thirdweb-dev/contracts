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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC721.sol";

//  ==========  Features    ==========
import "../extension/Ownable.sol";
import "../extension/PermissionsEnumerable.sol";

contract AirdropERC721 is
    Initializable,
    Ownable,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    IAirdropERC721
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC721");
    uint256 private constant VERSION = 1;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(address _defaultAdmin) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupOwner(_defaultAdmin);
        __ReentrancyGuard_init();
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
                            Airdrop logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets contract-owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    The contract address of the tokens to transfer.
     *  @param _tokenOwner      The owner of the the tokens to transfer.
     *  @param _contents        List containing recipient, tokenId to airdrop.
     */
    function airdrop(
        address _tokenAddress,
        address _tokenOwner,
        AirdropContent[] calldata _contents
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            try
                IERC721(_tokenAddress).safeTransferFrom{ gas: 80_000 }(
                    _tokenOwner,
                    _contents[i].recipient,
                    _contents[i].tokenId
                )
            {} catch {
                // revert if failure is due to unapproved tokens
                require(
                    (IERC721(_tokenAddress).ownerOf(_contents[i].tokenId) == _tokenOwner &&
                        address(this) == IERC721(_tokenAddress).getApproved(_contents[i].tokenId)) ||
                        IERC721(_tokenAddress).isApprovedForAll(_tokenOwner, address(this)),
                    "Not owner or approved"
                );

                emit AirdropFailed(_tokenAddress, _tokenOwner, _contents[i].recipient, _contents[i].tokenId);
            }

            unchecked {
                i += 1;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
