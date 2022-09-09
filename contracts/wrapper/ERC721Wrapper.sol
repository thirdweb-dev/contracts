// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/wrapper/IERC721Wrapper.sol";
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../eip/interface/IERC721Receiver.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Royalty.sol";
import "../extension/Ownable.sol";

contract ERC721Wrapper is
    Initializable,
    ContractMetadata,
    Royalty,
    Ownable,
    Multicall,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    ERC721Upgradeable,
    IERC721Wrapper
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("ERC721Wrapper");
    uint256 private constant VERSION = 1;

    /// @dev address of token being wrapped.
    address public tokenAddress;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => string) private _tokenURIs;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _tokenAddress,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);

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
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                    Wrapping / Unwrapping logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Wrap an ERC721 token.
    function wrap(
        address _recipient,
        uint256 _tokenId
    ) external nonReentrant {

        IERC721Upgradeable(tokenAddress).safeTransferFrom(_msgSender(), address(this), _tokenId);

        _setURI(_tokenId);
        _safeMint(_recipient, _tokenId);

        emit TokenWrapped(_msgSender(), _recipient, _tokenId);
    }

    /// @dev Unwrap a token to retrieve the underlying ERC721 token.
    function unwrap(address _recipient, uint256 _tokenId) external nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "caller not approved for unwrapping.");

        _burn(_tokenId);
        _resetURI(_tokenId);

        IERC721Upgradeable(tokenAddress).safeTransferFrom(address(this), _recipient, _tokenId);

        emit TokenUnwrapped(_msgSender(), _recipient, _tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _setURI(uint256 _tokenId) internal {
        _tokenURIs[_tokenId] = IERC721MetadataUpgradeable(tokenAddress).tokenURI(_tokenId);
    }

    function _resetURI(uint256 _tokenId) internal {
        delete _tokenURIs[_tokenId];
    }

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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
