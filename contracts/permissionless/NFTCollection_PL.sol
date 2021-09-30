// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "../NFTCollection.sol";

contract NFTCollection_PL is NFTCollection {
    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri
    ) NFTCollection(_controlCenter, _trustedForwarder, _uri) {
    }

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
        receiver = nftInfo[tokenId].creator;
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }
}
