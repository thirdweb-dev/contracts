// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "../Pack.sol";

contract Pack_PL is Pack {
    constructor(
        address payable _controlCenter,
        string memory _uri,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fees,
        address _trustedForwarder
    ) Pack(_controlCenter, _uri, _vrfCoordinator, _linkToken, _keyHash, _fees, _trustedForwarder) {}

    /// @dev Ignore MINTER_ROLE
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return role == MINTER_ROLE || super.hasRole(role, account);
    }

    /// @dev Revert regular mint
    function mint(
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("AccessNFT: cannot use regular mint function.");
    }

    /// @dev Revert regular mintBatch
    function mintBatch(
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("AccessNFT: cannot use regular mintBatch function.");
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = packs[tokenId].creator;
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }
}
