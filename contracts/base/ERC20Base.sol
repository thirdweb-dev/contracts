// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-presets/token/ERC20/extensions/ERC20Votes.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";

contract ERC20Base is 
    ERC20Votes,
    ContractMetadata,
    Multicall,
    Ownable
{
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI
    ) ERC20(_name, _symbol) 
    {
        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function mint(address _to, uint256 _amount) public virtual {
        require(_canMint(), "Not authorized to mint.");

        _mint(_to, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/
    
    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether tokens can be minted in the given execution context.
    function _canMint() internal virtual view returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }
}