// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../external-deps/openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

import "./ERC20Base.sol";
import "../extension/interface/IMintableERC20.sol";
import "../extension/interface/IBurnableERC20.sol";

/**
 *  The `ERC20Vote` smart contract implements the ERC20 standard and ERC20Votes.
 *  It includes the following additions to standard ERC20 logic:
 *
 *      - Ability to mint & burn tokens via the provided `mint` & `burn` functions.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - Extension of ERC20 to support voting and delegation.
 *
 *      - EIP 2612 compliance: See {ERC20-permit} method, which can be used to change an account's ERC20 allowance by
 *                             presenting a message signed by the account.
 */

contract ERC20Vote is ContractMetadata, Multicall, Ownable, ERC20Votes, IMintableERC20, IBurnableERC20 {
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol
    ) ERC20Permit(_name, _symbol) {
        _setupOwner(_defaultAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint tokens to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint tokens.
     *
     *  @param _to       The recipient of the tokens to mint.
     *  @param _amount   Quantity of tokens to mint.
     */
    function mintTo(address _to, uint256 _amount) public virtual {
        require(_canMint(), "Not authorized to mint.");
        require(_amount != 0, "Minting zero tokens.");

        _mint(_to, _amount);
    }

    /**
     *  @notice          Lets an owner a given amount of their tokens.
     *  @dev             Caller should own the `_amount` of tokens.
     *
     *  @param _amount   The number of tokens to burn.
     */
    function burn(uint256 _amount) external virtual {
        require(balanceOf(_msgSender()) >= _amount, "not enough balance");
        _burn(msg.sender, _amount);
    }

    /**
     *  @notice          Lets an owner burn a given amount of an account's tokens.
     *  @dev             `_account` should own the `_amount` of tokens.
     *
     *  @param _account  The account to burn tokens from.
     *  @param _amount   The number of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) external virtual override {
        require(_canBurn(), "Not authorized to burn.");
        require(balanceOf(_account) >= _amount, "not enough balance");
        uint256 decreasedAllowance = allowance(_account, msg.sender) - _amount;
        _approve(_account, msg.sender, 0);
        _approve(_account, msg.sender, decreasedAllowance);
        _burn(_account, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether tokens can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether tokens can be burned in the given execution context.
    function _canBurn() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
