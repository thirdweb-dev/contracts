// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "./ERC721Base.sol";

import "../../feature/Royalty.sol";

contract ERC721Royalty is 
    ERC721Base,
    Royalty 
{
    constructor(
        string memory _name, 
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721Base(_name, _symbol) {
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function _canSetRoyaltyInfo() internal virtual override view returns (bool) {
        return msg.sender == owner;
    }
}