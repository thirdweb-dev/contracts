// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/wrapper/IERC1155Wrapper.sol";
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../eip/interface/IERC1155Receiver.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Royalty.sol";
import "../extension/Ownable.sol";

contract ERC1155Wrapper is
    Initializable,
    ContractMetadata,
    Royalty,
    Ownable,
    Multicall,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    ERC1155Upgradeable,
    IERC1155Wrapper
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("ERC1155Wrapper");
    uint256 private constant VERSION = 1;

    /// @dev address of token being wrapped.
    address public tokenAddress;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        string memory _uri,
        address[] memory _trustedForwarders,
        address _tokenAddress,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155_init(_uri);

        // Initialize this contract's state.
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupOwner(_defaultAdmin);
        _setupContractURI(_contractURI);

        tokenAddress = _tokenAddress;
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
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                    Wrapping / Unwrapping logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Wrap ERC1155 tokens.
    function wrap(
        address _recipient,
        uint256 _tokenId,
        uint256 _amount
    ) external nonReentrant {
        IERC1155Upgradeable(tokenAddress).safeTransferFrom(_msgSender(), address(this), _tokenId, _amount, "");

        _mint(_recipient, _tokenId, _amount, "");

        emit TokenWrapped(_msgSender(), _recipient, _tokenId, _amount);
    }

    /// @dev Unwrap a token to retrieve the underlying ERC1155 tokens.
    function unwrap(
        address _recipient,
        uint256 _tokenId,
        uint256 _amount
    ) external nonReentrant {
        _burn(_msgSender(), _tokenId, _amount);

        IERC1155Upgradeable(tokenAddress).safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");

        emit TokenUnwrapped(_msgSender(), _recipient, _tokenId, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return _msgSender() == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return _msgSender() == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return _msgSender() == owner();
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
