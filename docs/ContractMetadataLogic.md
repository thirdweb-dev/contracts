# ContractMetadataLogic

*thirdweb.com*

> Contract Metadata

Thirdweb&#39;s `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI           for you contract.           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.



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

Lets a contract admin set the URI for contract-level metadata.

*Caller should be authorized to setup contractURI, e.g. contract admin.                  See {_canSetContractURI}.                  Emits {ContractURIUpdated Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |



## Events

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |



