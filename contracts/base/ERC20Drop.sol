// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  External imports    ==========

import "../openzeppelin-presets/token/ERC20/extensions/ERC20Votes.sol";

//  ==========  Internal imports    ==========

// import "./ERC20Base.sol";
import "../lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/PlatformFee.sol";
import "../extension/PrimarySale.sol";
import "../extension/PermissionsEnumerable.sol";
import {SignatureMintERC20 } from "../extension/SignatureMintERC20.sol";
import "../extension/DropSinglePhase.sol";

contract ERC20Drop is 
    ContractMetadata,
    Multicall,
    Ownable,
    PlatformFee,
    PrimarySale,
    PermissionsEnumerable,
    SignatureMintERC20,
    DropSinglePhase,
    ERC20Votes
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev The max number of tokens a wallet can claim.
    uint256 public maxWalletClaimCount;

    /// @dev Global max total supply of tokens.
    uint256 public maxTotalSupply;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from address => number of tokens a wallet has claimed.
    mapping(address => uint256) public walletClaimCount;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _primarySaleRecipient,
        address _platformFeeRecipient,
        uint256 _platformFeeBps
    ) ERC20(_name, _symbol) 
    {
        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));

        _setupPrimarySaleRecipient(_primarySaleRecipient);
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /*///////////////////////////////////////////////////////////////
                    ERC 165 + ERC20 transfer hooks
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC 165
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }
    }
}