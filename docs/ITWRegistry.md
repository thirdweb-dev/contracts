# ITWRegistry









## Methods

### add

```solidity
function add(address _deployer, address _deployment, uint256 _chainId) external nonpayable
```

Add a deployment for a deployer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | undefined |
| _deployment | address | undefined |
| _chainId | uint256 | undefined |

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
function getAll(address _deployer) external view returns (struct ITWRegistry.Deployment[] allDeployments)
```

Get all deployments for a deployer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _deployer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| allDeployments | ITWRegistry.Deployment[] | undefined |

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
event Added(address indexed deployer, address indexed deployment, uint256 indexed chainId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| deployer `indexed` | address | undefined |
| deployment `indexed` | address | undefined |
| chainId `indexed` | uint256 | undefined |

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



