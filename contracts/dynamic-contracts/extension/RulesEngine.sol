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
        mapping(uint256 => IRulesEngine.RuleWithId) rules;
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
                            View functions
    //////////////////////////////////////////////////////////////*/

    function getScore(address _tokenOwner) public view returns (uint256 score) {
        uint256 len = _rulesEngineStorage().nextRuleId;

        for (uint256 i = 0; i < len; i += 1) {
            Rule memory rule = _rulesEngineStorage().rules[i].rule;

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

    function getAllRules() external view returns (RuleWithId[] memory rules) {
        uint256 len = _rulesEngineStorage().nextRuleId;
        uint256 count = 0;

        for (uint256 i = 0; i < len; i += 1) {
            if (_rulesEngineStorage().rules[i].rule.token != address(0)) {
                count++;
            }
        }

        rules = new RuleWithId[](count);
        uint256 idx = 0;
        for (uint256 j = 0; j < len; j += 1) {
            if (_rulesEngineStorage().rules[j].rule.token != address(0)) {
                rules[idx++] = _rulesEngineStorage().rules[j];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function createRule(Rule memory rule) external returns (uint256 ruleId) {
        require(_canSetRules(), "RulesEngine: cannot set rules");
        ruleId = _createRule(rule);
    }

    function deleteRule(uint256 _ruleId) external {
        require(_canSetRules(), "RulesEngine: cannot set rules");
        _deleteRule(_ruleId);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    function _createRule(Rule memory _rule) internal returns (uint256 ruleId) {
        ruleId = _rulesEngineStorage().nextRuleId++;
        _rulesEngineStorage().rules[ruleId] = RuleWithId(ruleId, _rule);

        emit RuleCreated(ruleId, _rule);
    }

    function _deleteRule(uint256 _ruleId) internal {
        delete _rulesEngineStorage().rules[_ruleId];
    }

    function _rulesEngineStorage() internal pure returns (RulesEngineStorage.Data storage data) {
        data = RulesEngineStorage.rulesEngineStorage();
    }

    function _canSetRules() internal view virtual returns (bool);
}
