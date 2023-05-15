// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../eip/interface/IERC1155.sol";

import "../openzeppelin-presets/utils/Context.sol";
import "./interface/IMigrate1155.sol";

abstract contract Migrate1155 is Context, IMigrate1155 {
    address internal originERC1155Contract;
    mapping(uint256 => bool) private eligibleTokenIds;

    function migrateTokens(uint256 _tokenId, uint256 _amount) external virtual {
        address tokenOwner = _msgSender();

        verifyMigration(tokenOwner, _tokenId, _amount);
        _migrate(tokenOwner, _tokenId, _amount);

        // TODO: check if additional migration steps are required / override in main contract
    }

    function setTokensEligibleForMigration(uint256[] calldata _tokenIds) external virtual {
        require(_canSetTokenEligibility(), "Not authorized.");

        uint256 count = _tokenIds.length;
        for (uint256 i = 0; i < count; ) {
            eligibleTokenIds[_tokenIds[i]] = true;

            unchecked {
                i++;
            }
        }
    }

    function verifyMigration(
        address _tokenOwner,
        uint256 _tokenId,
        uint256 _amount
    ) public view virtual {
        require(eligibleTokenIds[_tokenId], "Can't migrate this token.");

        address _originContract = originERC1155Contract;
        require(IERC1155(_originContract).balanceOf(_tokenOwner, _tokenId) >= _amount, "Not enough balance.");

        // TODO: check if additional verification steps are required / override in main contract
    }

    function _setOriginContractForMigration(address _originERC1155Contract) internal {
        require(address(_originERC1155Contract) != address(0), "Invalid address for origin contract.");
        originERC1155Contract = _originERC1155Contract;
    }

    function _migrate(
        address _recipient,
        uint256 _tokenId,
        uint256 _amount
    ) internal virtual;

    function _canSetTokenEligibility() internal view virtual returns (bool);
}
