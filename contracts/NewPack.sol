// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NewPack {

    uint256 public nextTokenIdToMint;

    enum TokenType { ERC20, ERC721, ERC1155 }

    struct PackContent {
        address assetContract;
        TokenType tokenType;
        uint256 tokenId;
        uint256 totalAmountPacked;
        uint256 amountToDistributePerOpen;
    }

    struct PackInfo {
        PackContent[] contents;
        uint256 openStartTimestamp;
        string uri;
    }

    mapping(uint256 => PackInfo) public packInfo;

    function createPack(
        PackContent[] calldata _contents,
        string calldata _packUri,
        uint128 _openStartTimestamp
    ) 
        external
    {
        // Get packId
        uint256 packId = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        // Store pack contents
        packInfo[packId] = PackInfo({
            contents: _contents,
            openStartTimestamp: _openStartTimestamp,
            uri: _packUri
        });

        // Validate contents
        uint256 packAmountToMint;
        bool isValidAmounts;
        
        for(uint256 i = 0; i < _contents.length; i += 1) {

            // Validate total_amount is divisible by amount_per_open.
            isValidAmounts = _contents[i].totalAmountPacked % _contents[i].amountToDistributePerOpen == 0;
            if(!isValidAmounts) {
                break;
            }

            // # of packs to mint = sum of (total amounts / amount per open).
            packAmountToMint += _contents[i].totalAmountPacked / _contents[i].amountToDistributePerOpen;
            
            // Escorw the tokens to pack.
            if(_contents[i].tokenType == TokenType.ERC20) {
                
            } else if (_contents[i].tokenType == TokenType.ERC721) {

            } else if (_contents[i].tokenType == TokenType.ERC1155) {

            }
        }
        require(isValidAmounts, "invalid amounts specified.");

        // Mint packs

        // Emit event.
    }

    function openPack(uint256 _packId, uint256 _amountToOpen) external {

        // TODO: add require checks

        // Get pack.
        PackInfo memory pack = packInfo[_packId];
        
        // Get random number.
        uint256 randomNumber;

        // Distribute relevant pack contents.
        uint256 base; // base == total supply of packs

        for(uint256 i = 0; i < _amountToOpen; i += 1) {
            
            // Get random value for this iteration.
            uint256 randomValue = uint256(keccak256(abi.encode(randomNumber, i)));

            // Get target index.
            uint256 targetIndex = randomValue % base;

            // Track step
            uint256 step;

            for(uint256 j = 0; j < pack.contents.length; j += 1) {
                if(targetIndex < pack.contents[j].totalAmountPacked) {
                    // TODO: transfer pack content at index j

                    pack.contents[j].totalAmountPacked -= pack.contents[j].amountToDistributePerOpen;
                } else {
                    step += pack.contents[j].totalAmountPacked;
                }
            }
        }
    }
}