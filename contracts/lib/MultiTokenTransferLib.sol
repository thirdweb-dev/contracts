// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./CurrencyTransferLib.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

library MultiTokenTransferLib {
    struct MultiToken {
        address[] erc1155AssetContracts;
        uint256[][] erc1155TokensToWrap;
        uint256[][] erc1155AmountsToWrap;
        address[] erc721AssetContracts;
        uint256[][] erc721TokensToWrap;
        address[] erc20AssetContracts;
        uint256[] erc20AmountsToWrap;
    }

    function transferAll(
        address _from,
        address _to,
        MultiToken memory _multiToken
    ) internal {
        transferERC1155(_from, _to, _multiToken);
        transferERC721(_from, _to, _multiToken);
        transferERC20(_from, _to, _multiToken);
    }

    function transferERC20(
        address _from,
        address _to,
        MultiToken memory _multiToken
    ) internal {
        uint256 i;

        bool isValidData = _multiToken.erc20AssetContracts.length == _multiToken.erc20AmountsToWrap.length;
        require(isValidData, "invalid erc20 wrap");
        for (i = 0; i < _multiToken.erc20AssetContracts.length; i += 1) {
            CurrencyTransferLib.transferCurrency(
                _multiToken.erc20AssetContracts[i],
                _from,
                _to,
                _multiToken.erc20AmountsToWrap[i]
            );
        }
    }

    function transferERC721(
        address _from,
        address _to,
        MultiToken memory _multiToken
    ) internal {
        uint256 i;
        uint256 j;

        bool isValidData = _multiToken.erc721AssetContracts.length == _multiToken.erc721TokensToWrap.length;
        if (isValidData) {
            for (i = 0; i < _multiToken.erc721AssetContracts.length; i += 1) {
                IERC721Upgradeable assetContract = IERC721Upgradeable(_multiToken.erc721AssetContracts[i]);

                for (j = 0; j < _multiToken.erc721TokensToWrap[i].length; j += 1) {
                    assetContract.safeTransferFrom(_from, _to, _multiToken.erc721TokensToWrap[i][j]);
                }
            }
        }
        require(isValidData, "invalid erc721 wrap");
    }

    function transferERC1155(
        address _from,
        address _to,
        MultiToken memory _multiToken
    ) internal {
        uint256 i;
        uint256 j;

        bool isValidData = _multiToken.erc1155AssetContracts.length == _multiToken.erc1155TokensToWrap.length &&
            _multiToken.erc1155AssetContracts.length == _multiToken.erc1155AmountsToWrap.length;

        if (isValidData) {
            for (i = 0; i < _multiToken.erc1155AssetContracts.length; i += 1) {
                isValidData = _multiToken.erc1155TokensToWrap[i].length == _multiToken.erc1155AmountsToWrap[i].length;

                if (!isValidData) {
                    break;
                }

                IERC1155Upgradeable assetContract = IERC1155Upgradeable(_multiToken.erc1155AssetContracts[i]);

                for (j = 0; j < _multiToken.erc1155TokensToWrap[i].length; j += 1) {
                    assetContract.safeTransferFrom(
                        _from,
                        _to,
                        _multiToken.erc1155TokensToWrap[i][j],
                        _multiToken.erc1155AmountsToWrap[i][j],
                        ""
                    );
                }
            }
        }
        require(isValidData, "invalid erc1155 wrap");
    }
}
