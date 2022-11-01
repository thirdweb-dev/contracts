# IERC1822Proxiable







*ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified proxy whose upgrades are fully controlled by the current implementation.*

## Methods

### proxiableUUID

```solidity
function proxiableUUID() external view returns (bytes32)
```



*Returns the storage slot that the proxiable contract assumes is being used to store the implementation address. IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this function revert if invoked through a proxy.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |




