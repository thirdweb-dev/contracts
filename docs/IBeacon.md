# IBeacon







*This is the interface that {BeaconProxy} expects of its beacon.*

## Methods

### implementation

```solidity
function implementation() external view returns (address)
```



*Must return an address that can be used as a delegate call target. {BeaconProxy} will check that this address is a contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |




