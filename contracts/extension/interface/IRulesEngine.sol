// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IRulesEngine {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct Rule {
        address token;
        TokenType tokenType;
        uint256 tokenId;
        uint256 balance;
        uint256 score;
    }

    event RuleCreated(uint256 indexed ruleId, Rule rule);
    event RuleDeleted(uint256 indexed ruleId, Rule rule);

    function getScore(address _tokenOwner) external view returns (uint256 score);

    function createRule(Rule memory rule) external returns (uint256 ruleId);

    function deleteRule(uint256 ruleId) external;
}
