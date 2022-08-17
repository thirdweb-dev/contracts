# IContractDeployer









## Methods

### deployInstance

```solidity
function deployInstance(address publisher, bytes contractBytecode, bytes constructorArgs, bytes32 salt, uint256 value, string publishMetadataUri) external nonpayable returns (address deployedAddress)
```

Deploys an instance of a published contract directly.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |
| contractBytecode | bytes | The bytecode of the contract to deploy. |
| constructorArgs | bytes | The encoded constructor args to deploy the contract with. |
| salt | bytes32 | The salt to use in the CREATE2 contract deployment. |
| value | uint256 | The native token value to pass to the contract on deployment. |
| publishMetadataUri | string | The publish metadata URI for the contract to deploy. |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | The address of the contract deployed. |

### deployInstanceProxy

```solidity
function deployInstanceProxy(address publisher, address implementation, bytes initializeData, bytes32 salt, uint256 value, string publishMetadataUri) external nonpayable returns (address deployedAddress)
```

Deploys a clone pointing to an implementation of a published contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |
| implementation | address | The contract implementation for the clone to point to. |
| initializeData | bytes | The encoded function call to initialize the contract with. |
| salt | bytes32 | The salt to use in the CREATE2 contract deployment. |
| value | uint256 | The native token value to pass to the contract on deployment. |
| publishMetadataUri | string | The publish metadata URI and for the contract to deploy. |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | The address of the contract deployed. |

### getContractDeployer

```solidity
function getContractDeployer(address _contract) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _contract | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



## Events

### ContractDeployed

```solidity
event ContractDeployed(address indexed deployer, address indexed publisher, address deployedContract)
```



*Emitted when a contract is deployed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| deployer `indexed` | address | undefined |
| publisher `indexed` | address | undefined |
| deployedContract  | address | undefined |

### Paused

```solidity
event Paused(bool isPaused)
```



*Emitted when the registry is paused.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| isPaused  | bool | undefined |



