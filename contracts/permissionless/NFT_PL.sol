// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Token + Access Control
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "../NFT.sol";

contract NFT_PL is NFT {
    constructor(
        address payable _controlCenter,
        string memory _name,
        string memory _symbol,
        address _trustedForwarder,
        string memory _uri
    ) NFT(_controlCenter, _name, _symbol, _trustedForwarder, _uri) {}

    /// @dev Ignore MINTER_ROLE
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return role == MINTER_ROLE || super.hasRole(role, account);
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = nftCreator[tokenId];
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }
}
