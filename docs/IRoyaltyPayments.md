# IRoyaltyPayments







*Read royalty info for a token.      Supports RoyaltyEngineV1 and RoyaltyRegistry by manifold.xyz.*

## Methods

### getRoyalty

```solidity
function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external nonpayable returns (address payable[] recipients, uint256[] amounts)
```

Get the royalty for a given token (address, id) and value amount.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | - The address of the token |
| tokenId | uint256 | - The id of the token |
| value | uint256 | - The value you wish to get the royalty of returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get |

#### Returns

| Name | Type | Description |
|---|---|---|
| recipients | address payable[] | undefined |
| amounts | uint256[] | undefined |

### setRoyaltyEngine

```solidity
function setRoyaltyEngine(address _royaltyEngineAddress) external nonpayable
```

Set or override RoyaltyEngine address



#### Parameters

| Name | Type | Description |
|---|---|---|
| _royaltyEngineAddress | address | - RoyaltyEngineV1 address |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*Returns true if this contract implements the interface defined by `interfaceId`. See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section] to learn more about how these ids are created. This function call must use less than 30 000 gas.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### RoyaltyEngineUpdated

```solidity
event RoyaltyEngineUpdated(address indexed previousAddress, address indexed newAddress)
```



*Emitted when the address of RoyaltyEngine is set or updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| previousAddress `indexed` | address | undefined |
| newAddress `indexed` | address | undefined |



