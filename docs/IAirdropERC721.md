# IAirdropERC721





Thirdweb&#39;s `Airdrop` contracts provide a lightweight and easy to use mechanism  to drop tokens.  `AirdropERC721` contract is an airdrop contract for ERC721 tokens. It follows a  push mechanism for transfer of tokens to intended recipients.



## Methods

### airdrop

```solidity
function airdrop(address _tokenAddress, address _tokenOwner, address[] _recipients, uint256[] _tokenIds) external nonpayable
```

Lets contract-owner send ERC721 tokens to a list of addresses.

*The token-owner should approve target tokens to Airdrop contract,                   which acts as operator for the tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenAddress | address | Contract address of ERC721 tokens to air-drop. |
| _tokenOwner | address | Address from which to transfer tokens. |
| _recipients | address[] | List of recipient addresses for the air-drop. |
| _tokenIds | uint256[] | ERC721 token-Ids of tokens to drop. |




