# TWMultichainRegistryLogic









## Methods

### OPERATOR_ROLE

```solidity
function OPERATOR_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### _msgData

```solidity
function _msgData() external view returns (bytes)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### _msgSender

```solidity
function _msgSender() external view returns (address sender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| sender | address | undefined |

### add

```solidity
function add(address _deployer, address _deployment, uint256 _chainId, string metadataUri) external nonpayable
```

Add a deployment for a deployer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | undefined |
| _deployment | address | undefined |
| _chainId | uint256 | undefined |
| metadataUri | string | undefined |

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

### count

```solidity
function count(address _deployer) external view returns (uint256 deploymentCount)
```

Get the total number of deployments for a deployer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deploymentCount | uint256 | undefined |

### getAll

```solidity
function getAll(address _deployer) external view returns (struct ITWMultichainRegistry.Deployment[] allDeployments)
```

Get all deployments for a deployer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| allDeployments | ITWMultichainRegistry.Deployment[] | undefined |

### getMetadataUri

```solidity
function getMetadataUri(uint256 _chainId, address _deployment) external view returns (string metadataUri)
```

Returns the metadata IPFS URI for a deployment on a given chain if previously registered via add().



#### Parameters

| Name | Type | Description |
|---|---|---|
| _chainId | uint256 | undefined |
| _deployment | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| metadataUri | string | undefined |

### remove

```solidity
function remove(address _deployer, address _deployment, uint256 _chainId) external nonpayable
```

Remove a deployment for a deployer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | undefined |
| _deployment | address | undefined |
| _chainId | uint256 | undefined |



## Events

### Added

```solidity
event Added(address indexed deployer, address indexed deployment, uint256 indexed chainId, string metadataUri)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| deployer `indexed` | address | undefined |
| deployment `indexed` | address | undefined |
| chainId `indexed` | uint256 | undefined |
| metadataUri  | string | undefined |

### Deleted

```solidity
event Deleted(address indexed deployer, address indexed deployment, uint256 indexed chainId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| deployer `indexed` | address | undefined |
| deployment `indexed` | address | undefined |
| chainId `indexed` | uint256 | undefined |



