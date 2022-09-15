// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC721.sol";

//  ==========  Features    ==========
import "../extension/Ownable.sol";

contract AirdropERC721 is Initializable, Ownable, ReentrancyGuardUpgradeable, MulticallUpgradeable, IAirdropERC721 {
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
                            airdrop logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets contract-owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    Contract address of ERC721 tokens to air-drop.
     *  @param _tokenOwner      Address from which to transfer tokens.
     *  @param _recipients      List of recipient addresses for the air-drop.
     *  @param _tokenIds        ERC721 token-Ids of tokens to drop.
     */
    function airdrop(
        address _tokenAddress,
        address _tokenOwner,
        address[] memory _recipients,
        uint256[] memory _tokenIds
    ) external nonReentrant onlyOwner {
        uint256 len = _tokenIds.length;
        require(len == _recipients.length, "length mismatch");

        IERC721 token = IERC721(_tokenAddress);

        for (uint256 i = 0; i < len; i++) {
            token.safeTransferFrom(_tokenOwner, _recipients[i], _tokenIds[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
