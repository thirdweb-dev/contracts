# IContractMetadata





Thirdweb&#39;s `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI  for you contract.  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.



## Methods

### contractURI

```solidity
function contractURI() external view returns (string)
```



*Returns the metadata URI of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Sets contract URI for the storefront-level metadata of the contract.       Only module admin can call this function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined |



## Events

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```



*Emitted when the contract URI is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |



