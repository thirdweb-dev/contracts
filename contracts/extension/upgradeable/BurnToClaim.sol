// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "../../eip/interface/IERC1155.sol";
import "../../eip/interface/IERC721.sol";

import "../interface/IBurnToClaim.sol";

library BurnToClaimStorage {
    /// @custom:storage-location erc7201:burn.to.claim.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("burn.to.claim.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant BURN_TO_CLAIM_STORAGE_POSITION =
        0x6f0d20bed2d5528732497d5a17ac45087a6175b2a140eebe2a39ab447d7ad400;

    struct Data {
        IBurnToClaim.BurnToClaimInfo burnToClaimInfo;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = BURN_TO_CLAIM_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract BurnToClaim is IBurnToClaim {
    /// @notice Returns the confugration for burning tokens to claim new tokens.
    function getBurnToClaimInfo() public view returns (BurnToClaimInfo memory) {
        return _burnToClaimStorage().burnToClaimInfo;
    }

    /// @notice Sets the configuration for burning tokens to claim new tokens.
    function setBurnToClaimInfo(BurnToClaimInfo calldata _burnToClaimInfo) external virtual {
        require(_canSetBurnToClaim(), "Not authorized.");
        require(_burnToClaimInfo.originContractAddress != address(0), "Origin contract not set.");
        require(_burnToClaimInfo.currency != address(0), "Currency not set.");

        _burnToClaimStorage().burnToClaimInfo = _burnToClaimInfo;
    }

    /// @notice Verifies an attempt to burn tokens to claim new tokens.
    function verifyBurnToClaim(address _tokenOwner, uint256 _tokenId, uint256 _quantity) public view virtual {
        BurnToClaimInfo memory _burnToClaimInfo = getBurnToClaimInfo();

        if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC721) {
            require(_quantity == 1, "Invalid amount");
            require(IERC721(_burnToClaimInfo.originContractAddress).ownerOf(_tokenId) == _tokenOwner, "!Owner");
        } else if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC1155) {
            uint256 _eligible1155TokenId = _burnToClaimInfo.tokenId;

            require(_tokenId == _eligible1155TokenId, "Invalid token Id");
            require(
                IERC1155(_burnToClaimInfo.originContractAddress).balanceOf(_tokenOwner, _tokenId) >= _quantity,
                "!Balance"
            );
        }
    }

    /// @dev Burns tokens to claim new tokens.
    function _burnTokensOnOrigin(address _tokenOwner, uint256 _tokenId, uint256 _quantity) internal virtual {
        BurnToClaimInfo memory _burnToClaimInfo = getBurnToClaimInfo();

        if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC721) {
            ERC721Burnable(_burnToClaimInfo.originContractAddress).burn(_tokenId);
        } else if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC1155) {
            ERC1155Burnable(_burnToClaimInfo.originContractAddress).burn(_tokenOwner, _tokenId, _quantity);
        }
    }

    /// @dev Returns the BurnToClaimStorage storage.
    function _burnToClaimStorage() internal pure returns (BurnToClaimStorage.Data storage data) {
        data = BurnToClaimStorage.data();
    }

    /// @dev Returns whether the caller can set the burn to claim configuration.
    function _canSetBurnToClaim() internal view virtual returns (bool);
}
