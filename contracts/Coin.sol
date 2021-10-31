// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Token + Access Control
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "@openzeppelin/contracts/utils/Multicall.sol";

contract Coin is ERC20PresetMinterPauser, ERC2771Context, Multicall, ERC20Permit {
    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev Collection level metadata.
    string public _contractURI;

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.DEFAULT_ADMIN_ROLE(), _msgSender()),
            "Coin: only a protocol admin can call this function."
        );
        _;
    }

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin role");
        _;
    }

    event RestrictedTransferUpdated(bool transferable);

    constructor(
        address payable _controlCenter,
        string memory _name,
        string memory _symbol,
        address _trustedForwarder,
        string memory _uri
    ) ERC20PresetMinterPauser(_name, _symbol) ERC20Permit(_name) ERC2771Context(_trustedForwarder) {
        // Set the protocol control center
        controlCenter = ProtocolControl(_controlCenter);

        // Set contract URI
        _contractURI = _uri;

        _setupRole(TRANSFER_ROLE, _msgSender());
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20PresetMinterPauser, ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        if (transfersRestricted && from != address(0) && to != address(0)) {
            require(
                hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to),
                "Coin: Transfers are restricted to TRANSFER_ROLE holders"
            );
        }
    }

    /// @dev Lets a protocol admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

        emit RestrictedTransferUpdated(_restrictedTransfer);
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
