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
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC1155.sol";

//  ==========  Features    ==========
import "../extension/PermissionsEnumerable.sol";

contract AirdropERC1155 is
    Initializable,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    IAirdropERC1155
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC1155");
    uint256 private constant VERSION = 2;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(address _defaultAdmin) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
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
     *  @notice          Lets contract-owner send ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    The contract address of the tokens to transfer.
     *  @param _tokenOwner      The owner of the the tokens to transfer.
     *  @param _contents        List containing recipient, tokenId and amounts to airdrop.
     */
    function airdrop(
        address _tokenAddress,
        address _tokenOwner,
        AirdropContent[] calldata _contents
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            try
                IERC1155(_tokenAddress).safeTransferFrom{ gas: 80_000 }(
                    _tokenOwner,
                    _contents[i].recipient,
                    _contents[i].tokenId,
                    _contents[i].amount,
                    ""
                )
            {} catch {
                // revert if failure is due to unapproved tokens
                require(
                    IERC1155(_tokenAddress).balanceOf(_tokenOwner, _contents[i].tokenId) >= _contents[i].amount &&
                        IERC1155(_tokenAddress).isApprovedForAll(_tokenOwner, address(this)),
                    "Not balance or approved"
                );

                emit AirdropFailed(
                    _tokenAddress,
                    _tokenOwner,
                    _contents[i].recipient,
                    _contents[i].tokenId,
                    _contents[i].amount
                );
            }

            unchecked {
                i += 1;
            }
        }
    }
}
