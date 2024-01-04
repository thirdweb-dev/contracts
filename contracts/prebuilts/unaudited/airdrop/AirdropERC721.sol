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
import "../../../eip/interface/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../../extension/Multicall.sol";

//  ==========  Internal imports    ==========

import "../../interface/airdrop/IAirdropERC721.sol";
import "../../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";

//  ==========  Features    ==========
import "../../../extension/PermissionsEnumerable.sol";
import "../../../extension/ContractMetadata.sol";

contract AirdropERC721 is
    Initializable,
    ContractMetadata,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    Multicall,
    IAirdropERC721
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC721");
    uint256 private constant VERSION = 2;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders
    ) external initializer {
        __ERC2771Context_init_unchained(_trustedForwarders);

        _setupContractURI(_contractURI);
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
     *  @notice          Lets contract-owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    The contract address of the tokens to transfer.
     *  @param _tokenOwner      The owner of the tokens to transfer.
     *  @param _contents        List containing recipient, tokenId to airdrop.
     */
    function airdropERC721(
        address _tokenAddress,
        address _tokenOwner,
        AirdropContent[] calldata _contents
    ) external nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized.");

        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            try
                IERC721(_tokenAddress).safeTransferFrom(_tokenOwner, _contents[i].recipient, _contents[i].tokenId)
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

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev See ERC2771
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
