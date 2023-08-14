# RulesEngineExtension









## Methods

### createRuleMulitiplicative

```solidity
function createRuleMulitiplicative(IRulesEngine.RuleTypeMultiplicative rule) external nonpayable returns (bytes32 ruleId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rule | IRulesEngine.RuleTypeMultiplicative | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| ruleId | bytes32 | undefined |

### createRuleThreshold

```solidity
function createRuleThreshold(IRulesEngine.RuleTypeThreshold rule) external nonpayable returns (bytes32 ruleId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rule | IRulesEngine.RuleTypeThreshold | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| ruleId | bytes32 | undefined |

### deleteRule

```solidity
function deleteRule(bytes32 _ruleId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _ruleId | bytes32 | undefined |

### getAllRules

```solidity
function getAllRules() external view returns (struct IRulesEngine.RuleWithId[] rules)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| rules | IRulesEngine.RuleWithId[] | undefined |

### getRulesEngineOverride

```solidity
function getRulesEngineOverride() external view returns (address rulesEngineAddress)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| rulesEngineAddress | address | undefined |

### getScore

```solidity
function getScore(address _tokenOwner) external view returns (uint256 score)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenOwner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| score | uint256 | undefined |

### setRulesEngineOverride

```solidity
function setRulesEngineOverride(address _rulesEngineAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _rulesEngineAddress | address | undefined |



## Events

### RuleCreated

```solidity
event RuleCreated(bytes32 indexed ruleId, IRulesEngine.RuleWithId rule)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| ruleId `indexed` | bytes32 | undefined |
| rule  | IRulesEngine.RuleWithId | undefined |

### RuleDeleted

```solidity
event RuleDeleted(bytes32 indexed ruleId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| ruleId `indexed` | bytes32 | undefined |

### RulesEngineOverriden

```solidity
event RulesEngineOverriden(address indexed newRulesEngine)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRulesEngine `indexed` | address | undefined |



