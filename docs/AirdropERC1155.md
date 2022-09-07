# AirdropERC1155









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

### availableAmounts

```solidity
function availableAmounts(uint256) external view returns (uint256)
```



*number tokens available to claim for a tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### claim

```solidity
function claim(address _receiver, uint256 _quantity, uint256 _tokenId, bytes32[] _proofs, uint256 _proofMaxQuantityForWallet) external nonpayable
```



*Lets an account claim NFTs.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _quantity | uint256 | undefined |
| _tokenId | uint256 | undefined |
| _proofs | bytes32[] | undefined |
| _proofMaxQuantityForWallet | uint256 | undefined |

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
function initialize(address _defaultAdmin, address[] _trustedForwarders, address _tokenOwner, address _airdropTokenAddress, uint256[] _tokenIds, uint256[] _availableAmounts, uint256 _expirationTimestamp, uint256[] _maxWalletClaimCount, bytes32[] _merkleRoot) external nonpayable
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
| _availableAmounts | uint256[] | undefined |
| _expirationTimestamp | uint256 | undefined |
| _maxWalletClaimCount | uint256[] | undefined |
| _merkleRoot | bytes32[] | undefined |

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
function maxWalletClaimCount(uint256) external view returns (uint256)
```



*general claim limit for a tokenId if claimer not in allowlist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### merkleRoot

```solidity
function merkleRoot(uint256) external view returns (bytes32)
```



*mapping of tokenId to merkle root of the allowlist of addresses eligible to claim.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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
function supplyClaimedByWallet(uint256, address) external view returns (uint256)
```



*Mapping from tokenId and claimer address to total number of tokens claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | address | undefined |

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
function verifyClaim(address _claimer, uint256 _quantity, uint256 _tokenId, bool verifyMaxQuantityPerWallet) external view
```



*Checks a request to claim tokens against the active claim condition&#39;s criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _tokenId | uint256 | undefined |
| verifyMaxQuantityPerWallet | bool | undefined |

### verifyClaimMerkleProof

```solidity
function verifyClaimMerkleProof(address _claimer, uint256 _quantity, uint256 _tokenId, bytes32[] _proofs, uint256 _proofMaxQuantityForWallet) external view returns (bool validMerkleProof, uint256 merkleProofIndex)
```



*Checks whether a claimer meets the allowlist criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _tokenId | uint256 | undefined |
| _proofs | bytes32[] | undefined |
| _proofMaxQuantityForWallet | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| validMerkleProof | bool | undefined |
| merkleProofIndex | uint256 | undefined |



## Events

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



