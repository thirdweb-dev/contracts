// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../extension/interface/IRulesEngine.sol";

import "../../eip/interface/IERC20.sol";
import "../../eip/interface/IERC721.sol";
import "../../eip/interface/IERC1155.sol";

library RulesEngineStorage {
    bytes32 public constant RULES_ENGINE_STORAGE_POSITION = keccak256("rules.engine.storage");

    struct Data {
        uint256 nextRuleId;
        mapping(uint256 => IRulesEngine.Rule) rules;
    }

    function rulesEngineStorage() internal pure returns (Data storage rulesEngineData) {
        bytes32 position = RULES_ENGINE_STORAGE_POSITION;
        assembly {
            rulesEngineData.slot := position
        }
    }
}

abstract contract RulesEngine is IRulesEngine {
    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function getScore(address _tokenOwner) public view returns (uint256 score) {
        uint256 len = _rulesEngineStorage().nextRuleId;

        for (uint256 i = 0; i < len; i += 1) {
            Rule memory rule = _rulesEngineStorage().rules[i];

            if (rule.tokenType == TokenType.ERC20) {
                if (IERC20(rule.token).balanceOf(_tokenOwner) >= rule.balance) {
                    score += rule.score;
                }
            } else if (rule.tokenType == TokenType.ERC721) {
                if (IERC721(rule.token).balanceOf(_tokenOwner) >= rule.balance) {
                    score += rule.score;
                }
            } else if (rule.tokenType == TokenType.ERC1155) {
                if (IERC1155(rule.token).balanceOf(_tokenOwner, rule.tokenId) >= rule.balance) {
                    score += rule.score;
                }
            }
        }
    }

    function createRule(Rule memory rule) external returns (uint256 ruleId) {
        require(_canSetMetadataRules(), "RulesEngine: cannot set rules");
        ruleId = _createRule(rule);
    }

    function deleteRule(uint256 _ruleId) external {
        require(_canSetMetadataRules(), "RulesEngine: cannot set rules");
        _deleteRule(_ruleId);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    function _createRule(Rule memory _rule) internal returns (uint256 ruleId) {
        RulesEngineStorage.Data storage data = _rulesEngineStorage();
        ruleId = data.nextRuleId++;
        data.rules[ruleId] = _rule;

        emit RuleCreated(ruleId, _rule);
    }

    function _deleteRule(uint256 _ruleId) internal {
        RulesEngineStorage.Data storage data = _rulesEngineStorage();
        delete data.rules[_ruleId];
    }

    function _rulesEngineStorage() internal pure returns (RulesEngineStorage.Data storage data) {
        data = RulesEngineStorage.rulesEngineStorage();
    }

    function _canSetMetadataRules() internal view virtual returns (bool);
}
