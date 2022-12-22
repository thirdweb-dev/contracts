# IAccountInitialize





- One Signer can be a part of many Accounts.  - One Account can have many Signers.  - A Signer-AccountId pair hash can only be used/associated with one unique account.    i.e. a Signer must use unique accountId for each Account it wants to be a part of.  - How does data fetching work?      - Fetch all accounts for a single signer.      - Fetch all signers for a single account.      - Fetch the unique account for a signer-accountId pair.



## Methods

### initialize

```solidity
function initialize(address[] trustedForwarders, address controller, address signer) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| trustedForwarders | address[] | undefined |
| controller | address | undefined |
| signer | address | undefined |




