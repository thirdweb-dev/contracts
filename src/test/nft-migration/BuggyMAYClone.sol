// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/base/ERC721LazyMint.sol";
import "contracts/base/ERC1155Base.sol";
import "contracts/base/ERC721Drop.sol";

contract BuggyMAYClone is ERC721LazyMint {
    // Store constant values for the 2 NFT Collections:
    // 1. Is the BAYC NFT Collection
    ERC721LazyMint public immutable bayc;
    // 2. Is the Serum NFT Collection
    ERC1155Base public immutable serum;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _baycAddress,
        address _serumAddress
    ) ERC721LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        bayc = ERC721LazyMint(_baycAddress);
        serum = ERC1155Base(_serumAddress);
    }

    function verifyClaim(address _claimer, uint256 _quantity) public view virtual override {
        // 1. Override the claim function to ensure a few things:
        // - They own an NFT from the BAYClone contract
        require(bayc.balanceOf(_claimer) >= _quantity, "You don't own enough BAYC NFTs");
        // - They own an NFT from the SerumClone contract
        require(serum.balanceOf(_claimer, 0) >= _quantity, "You don't own enough Serum NFTs");
    }

    // 2. Within the claim, we need to burn 1 quantity of the serum
    // function claim(address _receiver, uint256 _quantity) public payable virtual override {
    //     // Use the rest of the inherited claim function logic
    //     super.claim(_receiver, _quantity);
    // }
    function _transferTokensOnClaim(address _receiver, uint256 _quantity) internal override returns (uint256) {
        // serum.burn(_receiver, 0, _quantity);
        return super._transferTokensOnClaim(_receiver, _quantity);
    }

    /// @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
    function _beforeTokenTransfers(
        address,
        address,
        uint256,
        uint256 quantity
    ) internal virtual override {
        // this hook is inherited from ERC721A
        // use this hook to apply any state changes before transfer of tokens or minting
        // this is to avoid any exploits or reentrancy like attacks

        // Add our custom logic to burn the serum NFTs from the caller
        serum.burn(
            msg.sender, // burn serum of claimer
            0,
            quantity
        );
    }
}
