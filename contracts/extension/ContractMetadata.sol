// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RebelByNature is ERC721URIStorage, Ownable, ContractMetadata {
    uint256 public nextTokenId;

    event TributeMinted(uint256 tokenId, address recipient, uint256 timestamp);

    constructor() ERC721("Rebel By Nature", "SEQREB") {}

    function mintTribute(address recipient) external onlyOwner {
        uint256 tokenId = nextTokenId++;
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, contractURI);
        emit TributeMinted(tokenId, recipient, block.timestamp);
    }

    function _canSetContractURI() internal view override returns (bool) {
        return msg.sender == owner();
    }
}
