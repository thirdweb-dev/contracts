// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IRulesEngine {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum RuleType {
        Threshold,
        Multiplicative
    }

    struct RuleTypeThreshold {
        address token;
        TokenType tokenType;
        uint256 tokenId;
        uint256 balance;
        uint256 score;
    }

    struct RuleTypeMultiplicative {
        address token;
        TokenType tokenType;
        uint256 tokenId;
        uint256 scorePerOwnedToken;
    }

    struct RuleWithId {
        bytes32 ruleId;
        address token;
        TokenType tokenType;
        uint256 tokenId;
        uint256 balance;
        uint256 score;
        RuleType ruleType;
    }

    event RuleCreated(bytes32 indexed ruleId, RuleWithId rule);
    event RuleDeleted(bytes32 indexed ruleId);
    event RulesEngineOverriden(address indexed newRulesEngine);

    function getScore(address _tokenOwner) external view returns (uint256 score);

    function getAllRules() external view returns (RuleWithId[] memory rules);

    function getRulesEngineOverride() external view returns (address rulesEngineAddress);

    function createRuleMultiplicative(RuleTypeMultiplicative memory rule) external returns (bytes32 ruleId);

    function createRuleThreshold(RuleTypeThreshold memory rule) external returns (bytes32 ruleId);

    function deleteRule(bytes32 ruleId) external;

    function setRulesEngineOverride(address _rulesEngineAddress) external;
}
