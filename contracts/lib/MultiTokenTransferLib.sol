// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./CurrencyTransferLib.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

library MultiTokenTransferLib {

    struct Bundle {
        address[] erc1155AssetContracts;
        uint256[][] erc1155TokensToWrap;
        uint256[][] erc1155AmountsToWrap;
        address[] erc721AssetContracts;
        uint256[][] erc721TokensToWrap;
        address[] erc20AssetContracts;
        uint256[] erc20AmountsToWrap;
    }

    function transferBundle(
        address _from,
        address _to,
        Bundle memory _bundle
    ) internal {
        transfer1155(_from, _to, _bundle);
        transfer721(_from, _to, _bundle);
        transfer20(_from, _to, _bundle);
    }

    function transfer20(
        address _from,
        address _to,
        Bundle memory _bundle
    ) internal {
        uint256 i;

        bool isValidData = _bundle.erc20AssetContracts.length == _bundle.erc20AmountsToWrap.length;
        require(isValidData, "invalid erc20 wrap");
        for (i = 0; i < _bundle.erc20AssetContracts.length; i += 1) {
            CurrencyTransferLib.transferCurrency(
                _bundle.erc20AssetContracts[i],
                _from,
                _to,
                _bundle.erc20AmountsToWrap[i]
            );
        }
    }

    function transfer721(
        address _from,
        address _to,
        Bundle memory _bundle
    ) internal {
        uint256 i;
        uint256 j;

        bool isValidData = _bundle.erc721AssetContracts.length == _bundle.erc721TokensToWrap.length;
        if (isValidData) {
            for (i = 0; i < _bundle.erc721AssetContracts.length; i += 1) {
                IERC721Upgradeable assetContract = IERC721Upgradeable(_bundle.erc721AssetContracts[i]);

                for (j = 0; j < _bundle.erc721TokensToWrap[i].length; j += 1) {
                    assetContract.safeTransferFrom(_from, _to, _bundle.erc721TokensToWrap[i][j]);
                }
            }
        }
        require(isValidData, "invalid erc721 wrap");
    }

    function transfer1155(
        address _from,
        address _to,
        Bundle memory _bundle
    ) internal {
        uint256 i;
        uint256 j;

        bool isValidData = _bundle.erc1155AssetContracts.length ==
            _bundle.erc1155TokensToWrap.length &&
            _bundle.erc1155AssetContracts.length == _bundle.erc1155AmountsToWrap.length;

        if (isValidData) {
            for (i = 0; i < _bundle.erc1155AssetContracts.length; i += 1) {
                isValidData =
                    _bundle.erc1155TokensToWrap[i].length == _bundle.erc1155AmountsToWrap[i].length;

                if (!isValidData) {
                    break;
                }

                IERC1155Upgradeable assetContract = IERC1155Upgradeable(_bundle.erc1155AssetContracts[i]);

                for (j = 0; j < _bundle.erc1155TokensToWrap[i].length; j += 1) {
                    assetContract.safeTransferFrom(
                        _from,
                        _to,
                        _bundle.erc1155TokensToWrap[i][j],
                        _bundle.erc1155AmountsToWrap[i][j],
                        ""
                    );
                }
            }
        }
        require(isValidData, "invalid erc1155 wrap");
    }

}
