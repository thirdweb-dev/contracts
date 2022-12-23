# ISignerTracker





- The Account can have many Signers.  - There are two kinds of signers: `Admin`s and `Operator`s.    Each `Admin` can:      - Perform any transaction / action on this account with 1/n approval.      - Add signers or remove existing signers.      - Approve a particular smart contract call (i.e. fn signature + contract address) for an `Operator`.    Each `Operator` can:      - Perform smart contract calls it is approved for (i.e. wherever Operator =&gt; (fn signature + contract address) =&gt; TRUE).  - The Account can:      - Deploy smart contracts.      - Send native tokens.      - Call smart contracts.      - Sign messages. (EIP-1271)      - Own and transfer assets. (ERC-20/721/1155)



## Methods

### addSignerToAccount

```solidity
function addSignerToAccount(address signer, bytes32 accountId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| accountId | bytes32 | undefined |

### removeSignerToAccount

```solidity
function removeSignerToAccount(address signer, bytes32 accountId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| accountId | bytes32 | undefined |




