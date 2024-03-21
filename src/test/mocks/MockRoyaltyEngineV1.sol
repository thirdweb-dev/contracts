// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/interface/IRoyaltyEngineV1.sol";
import { IERC2981 } from "contracts/eip/interface/IERC2981.sol";
import { ERC165 } from "contracts/eip/ERC165.sol";

contract MockRoyaltyEngineV1 is ERC165, IRoyaltyEngineV1 {
    address payable[] public mockRecipients;
    uint256[] public mockAmounts;

    constructor(address payable[] memory _mockRecipients, uint256[] memory _mockAmounts) {
        mockRecipients = _mockRecipients;
        mockAmounts = _mockAmounts;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) public view override returns (address payable[] memory recipients, uint256[] memory amounts) {
        try IERC2981(tokenAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
            // Supports EIP2981.  Return amounts
            recipients = new address payable[](1);
            amounts = new uint256[](1);
            recipients[0] = payable(recipient);
            amounts[0] = amount;
            return (recipients, amounts);
        } catch {}

        // Non ERC2981. Return mock recipients/amounts.
        recipients = mockRecipients;
        amounts = mockAmounts;
        return (recipients, amounts);
    }

    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) public view override returns (address payable[] memory recipients, uint256[] memory amounts) {}
}
