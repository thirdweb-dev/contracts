# IDropERC20





`LazyMintERC20` is an ERC 20 contract.  The module admin can create claim conditions with non-overlapping time windows,  and accounts can claim the tokens, in a given time window, according to restrictions  defined in that time window&#39;s claim conditions.



## Methods

### claim

```solidity
function claim(address _receiver, uint256 _quantity, address _currency, uint256 _pricePerToken, bytes32[] _proofs, uint256 _proofMaxQuantityPerTransaction) external payable
```

Lets an account claim a given quantity of tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | The receiver of the NFTs to claim.
| _quantity | uint256 | The quantity of tokens to claim.
| _currency | address | The currency in which to pay for the claim.
| _pricePerToken | uint256 | The price per token to pay for the claim.
| _proofs | bytes32[] | The proof required to prove the account&#39;s inclusion in the merkle root whitelist                 of the mint conditions that apply.
| _proofMaxQuantityPerTransaction | uint256 | The maximum claim quantity per transactions that included in the merkle proof.

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the module type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### contractURI

```solidity
function contractURI() external view returns (string)
```



*Returns the metadata URI of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined

### getPlatformFeeInfo

```solidity
function getPlatformFeeInfo() external view returns (address platformFeeRecipient, uint16 platformFeeBps)
```



*Returns the platform fee bps and recipient.*


#### Returns

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient | address | undefined
| platformFeeBps | uint16 | undefined

### primarySaleRecipient

```solidity
function primarySaleRecipient() external view returns (address)
```



*The adress that receives all primary sales value.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### setClaimConditions

```solidity
function setClaimConditions(IDropClaimCondition.ClaimCondition[] _phases, bool _resetLimitRestriction) external nonpayable
```

Lets a module admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _phases | IDropClaimCondition.ClaimCondition[] | Mint conditions in ascending order by `startTimestamp`.
| _resetLimitRestriction | bool | To reset claim phases limit restriction.

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Sets contract URI for the storefront-level metadata of the contract.       Only module admin can call this function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined

### setPlatformFeeInfo

```solidity
function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external nonpayable
```



*Lets a module admin update the fees on primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _platformFeeRecipient | address | undefined
| _platformFeeBps | uint256 | undefined

### setPrimarySaleRecipient

```solidity
function setPrimarySaleRecipient(address _saleRecipient) external nonpayable
```



*Lets a module admin set the default recipient of all primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _saleRecipient | address | undefined



## Events

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IDropClaimCondition.ClaimCondition[] claimConditions)
```



*Emitted when new claim conditions are set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IDropClaimCondition.ClaimCondition[] | undefined |

### MaxTotalSupplyUpdated

```solidity
event MaxTotalSupplyUpdated(uint256 maxTotalSupply)
```



*Emitted when a max total supply is set for a token.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| maxTotalSupply  | uint256 | undefined |

### MaxWalletClaimCountUpdated

```solidity
event MaxWalletClaimCountUpdated(uint256 count)
```



*Emitted when the max wallet claim count is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| count  | uint256 | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps)
```



*Emitted when fee on primary sales is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient  | address | undefined |
| platformFeeBps  | uint256 | undefined |

### PrimarySaleRecipientUpdated

```solidity
event PrimarySaleRecipientUpdated(address indexed recipient)
```



*Emitted when a new sale recipient is set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 quantityClaimed)
```



*Emitted when tokens are claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| quantityClaimed  | uint256 | undefined |

### WalletClaimCountUpdated

```solidity
event WalletClaimCountUpdated(address indexed wallet, uint256 count)
```



*Emitted when a wallet claim count is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| wallet `indexed` | address | undefined |
| count  | uint256 | undefined |



