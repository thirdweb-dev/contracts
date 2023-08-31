// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "../eip/interface/IERC1155.sol";
import "../eip/interface/IERC721.sol";

import "../external-deps/openzeppelin/utils/Context.sol";
import "./interface/IBurnToClaim.sol";

abstract contract BurnToClaim is IBurnToClaim {
    BurnToClaimInfo internal burnToClaimInfo;

    function setBurnToClaimInfo(BurnToClaimInfo calldata _burnToClaimInfo) external virtual {
        require(_canSetBurnToClaim(), "Not authorized.");

        burnToClaimInfo = _burnToClaimInfo;
    }

    function verifyBurnToClaim(
        address _tokenOwner,
        uint256 _tokenId,
        uint256 _quantity
    ) public view virtual {
        BurnToClaimInfo memory _burnToClaimInfo = burnToClaimInfo;

        if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC721) {
            require(_quantity == 1, "Invalid amount");
            require(IERC721(_burnToClaimInfo.originContractAddress).ownerOf(_tokenId) == _tokenOwner);
        } else if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC1155) {
            uint256 _eligible1155TokenId = _burnToClaimInfo.tokenId;

            require(_tokenId == _eligible1155TokenId || _eligible1155TokenId == type(uint256).max);
            require(IERC1155(_burnToClaimInfo.originContractAddress).balanceOf(_tokenOwner, _tokenId) >= _quantity);
        }

        // TODO: check if additional verification steps are required / override in main contract
    }

    function _burnTokensOnOrigin(
        address _tokenOwner,
        uint256 _tokenId,
        uint256 _quantity
    ) internal virtual {
        BurnToClaimInfo memory _burnToClaimInfo = burnToClaimInfo;
        if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC721) {
            ERC721Burnable(_burnToClaimInfo.originContractAddress).burn(_tokenId);
        } else if (_burnToClaimInfo.tokenType == IBurnToClaim.TokenType.ERC1155) {
            ERC1155Burnable(_burnToClaimInfo.originContractAddress).burn(_tokenOwner, _tokenId, _quantity);
        }
        // TODO: check if additional migration steps are required / override in main contract
    }

    function _canSetBurnToClaim() internal view virtual returns (bool);
}
