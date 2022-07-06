// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20Base.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/PlatformFee.sol";
import "../../feature/Royalty.sol";
import "../../feature/PrimarySale.sol";
import "../../feature/Ownable.sol";
import "../../feature/DelayedReveal.sol";
import "../../feature/LazyMint.sol";
import "../../feature/PermissionsEnumerable.sol";
import "../../feature/Drop.sol";

contract ERC20Drop is 
    ERC20Base,
    PlatformFee,
    PrimarySale,
    PermissionsEnumerable,
    Drop
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint128 internal constant MAX_BPS = 10_000;

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
        string memory _name, 
        string memory _symbol,
        string memory _contractURI
    ) ERC20Base(_name, _symbol, _contractURI) 
    {}

    
}