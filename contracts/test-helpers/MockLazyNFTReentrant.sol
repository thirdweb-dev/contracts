// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../LazyNFT.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MockLazyNFTReentrant is IERC721Receiver {
    LazyNFT nft;

    constructor(address _addy) {
        nft = LazyNFT(_addy);
    }

    function attack() external {
        bytes32[] memory proofs = new bytes32[](0);
        Address.functionCallWithValue(address(nft), abi.encodeWithSelector(nft.claim.selector, 1, proofs), 1 ether, "FAILED");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        bytes32[] memory proofs = new bytes32[](0);
        Address.functionCallWithValue(address(nft), abi.encodeWithSelector(nft.claim.selector, 1, proofs), 1 ether, "FAILED");
        return this.onERC721Received.selector;
    }

    receive() external payable {
    }
}
