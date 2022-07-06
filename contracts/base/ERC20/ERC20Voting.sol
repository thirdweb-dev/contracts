// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20Base.sol";

contract ERC20Voting is 
    ERC20Base
{
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