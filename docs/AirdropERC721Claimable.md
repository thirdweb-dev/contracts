# AirdropERC721Claimable









## Methods

### airdropTokenAddress

```solidity
function airdropTokenAddress() external view returns (address)
```



*address of token being airdropped.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### availableAmount

```solidity
function availableAmount() external view returns (uint256)
```



*number tokens available to claim in tokenIds[].*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### claim

```solidity
function claim(address _receiver, uint256 _quantity, bytes32[] _proofs, uint256 _proofMaxQuantityForWallet) external nonpayable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | The receiver of the NFTs to claim. |
| _quantity | uint256 | The quantity of NFTs to claim. |
| _proofs | bytes32[] | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply. |
| _proofMaxQuantityForWallet | uint256 | The maximum number of NFTs an address included in an                                        allowlist can claim. |

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### expirationTimestamp

```solidity
function expirationTimestamp() external view returns (uint256)
```



*airdrop expiration timestamp.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin, address[] _trustedForwarders, address _tokenOwner, address _airdropTokenAddress, uint256[] _tokenIds, uint256 _expirationTimestamp, uint256 _maxWalletClaimCount, bytes32 _merkleRoot) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |
| _trustedForwarders | address[] | undefined |
| _tokenOwner | address | undefined |
| _airdropTokenAddress | address | undefined |
| _tokenIds | uint256[] | undefined |
| _expirationTimestamp | uint256 | undefined |
| _maxWalletClaimCount | uint256 | undefined |
| _merkleRoot | bytes32 | undefined |

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### maxWalletClaimCount

```solidity
function maxWalletClaimCount() external view returns (uint256)
```



*general claim limit if claimer not in allowlist.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### merkleRoot

```solidity
function merkleRoot() external view returns (bytes32)
```



*merkle root of the allowlist of addresses eligible to claim.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |

### nextIndex

```solidity
function nextIndex() external view returns (uint256)
```



*next index in tokenIds[] to claim in the airdrop.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```

Lets an authorized wallet set a new owner for the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address to set as the new owner of the contract. |

### supplyClaimedByWallet

```solidity
function supplyClaimedByWallet(address) external view returns (uint256)
```



*Mapping from address =&gt; total number of tokens a wallet has claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### tokenIds

```solidity
function tokenIds(uint256) external view returns (uint256)
```



*list of tokens to airdrop.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### tokenOwner

```solidity
function tokenOwner() external view returns (address)
```



*address of owner of tokens being airdropped.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### verifyClaim

```solidity
function verifyClaim(address _claimer, uint256 _quantity, bytes32[] _proofs, uint256 _proofMaxQuantityForWallet) external view
```



*Checks a request to claim tokens against the active claim condition&#39;s criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _proofs | bytes32[] | undefined |
| _proofMaxQuantityForWallet | uint256 | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address indexed prevOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| quantityClaimed  | uint256 | undefined |



