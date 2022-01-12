// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IThirdwebModule.sol";
import "./TWAccessControl.sol";
import "./TWPayments.sol";
import "./TWUtils.sol";

abstract contract TWModule is
    IThirdwebModule,
    TWUtils,
    TWPayments,
    TWAccessControl
{

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Checks whether the caller is a module admin.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    constructor(address _nativeTokenWrapper, address _thirdwebFees)
        initializer
        TWPayments(_nativeTokenWrapper, _thirdwebFees)
    {}

    function __TWModule_init(
        string memory _contractURI,
        address _trustedForwarder,
        address _royaltyRecipient,
        uint256 _royaltyBps
    )
        internal
        onlyInitializing
    {
        __TWUtils_init(_trustedForwarder);
        __TWPayments_init(_royaltyRecipient, _royaltyBps);
        __TWAccessControl_init(_msgSender());

        __TWModule_init_unchained(_contractURI);
    }

    function __TWModule_init_unchained(string memory _contractURI) internal onlyInitializing {
        contractURI = _contractURI;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyModuleAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit NewOwner(_prevOwner, _newOwner);
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyModuleAdmin {
        contractURI = _uri;
    }

    /// @dev See ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(TWPayments, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev For meta-tx support.
    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev For meta-tx support.
    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}