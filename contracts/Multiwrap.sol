// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Base
import "./openzeppelin-presets/ERC1155PresetUpgradeable.sol";

// Token interfaces
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Helpers
import "./lib/CurrencyTransferLib.sol";

/**
 *      - Wrap multiple ERC721 and ERC20 tokens into 'n' shares (i.e. variable supply of 1 ERC 1155 token)
 */

contract Multiwrap is ERC1155PresetUpgradeable {

    uint256 public nextTokenIdToMint;

    mapping(uint256 => string) private uriForShares;
    mapping(uint256 => WrappedContents) private wrappedContents;

    struct WrappedContents {
        address[] erc1155AssetContracts;
        uint256[][] erc1155TokensToWrap;
        uint256[][] erc1155AmountsToWrap;
        address[] erc721AssetContracts;
        uint256[][] erc721TokensToWrap;
        address[] erc20AssetContracts;
        uint256[] erc20AmountsToWrap;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return uriForShares[_tokenId];
    }

    // TODO: initialize function
    // TODO: TW regulars i.e. `contractURI` etc.

    // TODO: require checks.
    function wrap(
        WrappedContents calldata _wrappedContents,
        uint256 _shares,
        string calldata _uriForShares
    )
        external
    {
        uint256 tokenId = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        uriForShares[tokenId] = _uriForShares;
        wrappedContents[tokenId] = _wrappedContents;

        _mint(msg.sender, tokenId, _shares, "");

        transferWrappedAssets(msg.sender, address(this), _wrappedContents);
    }

    // TODO: require checks
    function unwrap(uint256 _tokenId) external {
        WrappedContents memory _wrappedContents = wrappedContents[_tokenId];

        delete wrappedContents[_tokenId];

        burn(msg.sender, _tokenId, totalSupply(_tokenId));

        transferWrappedAssets(address(this), msg.sender, _wrappedContents);
    }

    // TODO: require checks
    function transferWrappedAssets(
        address _from,
        address _to,
        WrappedContents memory _wrappedContents
    ) 
        internal
    {

        uint256 i;
        uint256 j;

        for(i = 0; i < _wrappedContents.erc1155AssetContracts.length; i += 1) {
            IERC1155 assetContract = IERC1155(_wrappedContents.erc1155AssetContracts[i]);
            
            for(j = 0; j < _wrappedContents.erc1155TokensToWrap[i].length; j +=1) {
                assetContract.safeTransferFrom(_from, _to, _wrappedContents.erc1155TokensToWrap[i][j], _wrappedContents.erc1155AmountsToWrap[i][j], "");
            }
        }

        for(i = 0; i < _wrappedContents.erc721AssetContracts.length; i += 1) {
            IERC721 assetContract = IERC721(_wrappedContents.erc721AssetContracts[i]);
            
            for(j = 0; j < _wrappedContents.erc721TokensToWrap[i].length; j +=1) {
                assetContract.safeTransferFrom(_from, _to, _wrappedContents.erc721TokensToWrap[i][j]);
            }
        }

        for(i = 0; i < _wrappedContents.erc20AssetContracts.length; i += 1) {
            CurrencyTransferLib.transferCurrency(
                _wrappedContents.erc20AssetContracts[i],
                _from,
                _to,
                _wrappedContents.erc20AmountsToWrap[i]
            );
        }

    }
}