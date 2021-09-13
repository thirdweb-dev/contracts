# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Difference from `main`

The contracts in this branch `create-in-one-tx` have a different flow for creating packs.

### Creating Packs: Before (in `main`)

Creating packs was a 3 step process:

- Create rewards with `Rewards.sol` by calling e.g. `createNativeRewards`
- Approve `Pack.sol` to transfer the created rewards, by calling `setApprovalForAll`.
- Create packs with `Pack.sol` by calling `createPack`.

### Creating Packs: Now (in `create-in-one-tx`)

Creating packs is now a one step process:

- Call `createPackAtomic` in `Rewards.sol` with the relevant arguments.

On calling `createPackAtomic`, the contracts first mints rewards to the creator, and then transfers the rewards from the caller to `Pack.sol`. On receiving the rewards, `Pack.sol` mints packs to the creator with the sent underlying rewards.

The `data` argument in `safeTransferFrom` allows sending whatever information to `Pack.sol` that is required to create the relevant packs.

**Note:** Creating packs with wrapped rewards is a two step process:

- First create your rewards by calling the relevant reward creation function e.g. `wrapERC721`.

- Call `createPack` in `Rewards.sol` with the relevant arguments.

## Notes for AccessPacks frontend integration

### Creating packs with rewards

The entire create flow is a now one step (just one frontend call):

- **Create packs with rewards:** Call `createPackAtomic` on `Rewards.sol`. The interface is:

```java
/// @dev Creates packs with rewards.
	function createPackAtomic(
		string[] calldata _rewardURIs,
		uint[] calldata _rewardSupplies,

		string calldata _packURI,
		uint _secondsUntilOpenStart,
    uint _secondsUntilOpenEnd
	) external {}
```

### Listing packs for sale

The list-for-sale flow is a two step process (two frontend calls)

- **Approve market to transfer tokens being listed for sale:** This approval needs to be given only once _ever_ (unless the user has removed the approval at a later time).

```javascript
// First check if approval already exists
await packContract.isApprovedForAll(userAddress, marketAddress);

// If no approval, ask user for approval
await packContract.connect(useSigner).setApprovalForAll(marketAddress, true);
```

- **List packs on market:** Call `list` on `Market.sol`. The interface is:

```java
/// @notice List a given amount of pack or reward tokens for sale.
  function list(
    address _assetContract,
    uint _tokenId,

    address _currency,
    uint _pricePerToken,
    uint _quantity,

    uint _secondsUntilStart,
    uint _secondsUntilEnd
  ) external onlyUnpausedProtocol {}
```

## Deployments

The contracts in the `/contracts` directory are deployed on the following networks.

### Polygon

- `ProtocolControl.sol`: [0x429ACf993C992b322668122a5fC5593200493ea8](https://polygonscan.com/address/0x429ACf993C992b322668122a5fC5593200493ea8#code)

- `Pack.sol`: [0x3d5a51975fD29E45Eb285349F12b77b4c153c8e0](https://polygonscan.com/address/0x3d5a51975fD29E45Eb285349F12b77b4c153c8e0#code)

- `Market.sol`: [0xfC958641E52563f071534495886A8Ac590DCBFA2](https://polygonscan.com/address/0xfC958641E52563f071534495886A8Ac590DCBFA2#code)

- `Rewards.sol`: [0x58408Fa085ae3942C3A6532ee6215bFC7f80c47A](https://polygonscan.com/address/0x58408Fa085ae3942C3A6532ee6215bFC7f80c47A#code)

### Mumbai

- `ProtocolControl.sol`: [0x3d86dD9846c0a15B0f40037AAf51CC68A4236add](https://mumbai.polygonscan.com/address/0x3d86dD9846c0a15B0f40037AAf51CC68A4236add#code)

- `Pack.sol`: [0xD89eE4F34BC76315E77D808305c0931f28Fa3C5D](https://mumbai.polygonscan.com/address/0xD89eE4F34BC76315E77D808305c0931f28Fa3C5D#code)

- `Market.sol`: [0xF1089C7a0Ae7d0729d94ff6806d7BeA0A02C3bF2](https://mumbai.polygonscan.com/address/0xF1089C7a0Ae7d0729d94ff6806d7BeA0A02C3bF2#code)

- `Rewards.sol`: [0x7c6c7048Cd447BA200bde9A89A2ECc83435b7E51](https://mumbai.polygonscan.com/address/0x7c6c7048Cd447BA200bde9A89A2ECc83435b7E51#code)

### Rinkeby

- `ProtocolControl.sol`: [0xAFe8f8EDad3Fd7b0108997b51CCd24286FbF000B](https://rinkeby.etherscan.io/address/0xAFe8f8EDad3Fd7b0108997b51CCd24286FbF000B#code)

- `Pack.sol`: [0x928C9EE38048e5D0A4601D1FDcF7B9E57317278D](https://rinkeby.etherscan.io/address/0x928C9EE38048e5D0A4601D1FDcF7B9E57317278D#code)

- `Market.sol`: [0xE0C0158A9d498EF4D0b02a8256A6957718Af8B5B](https://rinkeby.etherscan.io/address/0xE0C0158A9d498EF4D0b02a8256A6957718Af8B5B#code)

- `Rewards.sol`: [0xebC0b11f62A416634fe400bbB750f0E40833a4d0](https://rinkeby.etherscan.io/address/0xebC0b11f62A416634fe400bbB750f0E40833a4d0#code)

## Run Locally

Clone the project

```bash
  git clone https://github.com/nftlabs/pack-protocol.git
```

Install dependencies

```bash
  yarn install
```

## Run tests and scripts

Add a `.env` file to the project's root directory. Update the `.env` file with the values mentioned in the provided `.env.example` file.

Run tests

```bash
  npx hardhat test
```

To use scripts, update the transaction parameters in the particular script and run

```bash
  npx hardhat run scripts/.../${testFileName}.ts --network {name of network}
```

## Deploying contracts

To deploy this project on a given network (e.g. mumbai) update the `hardhat.config.ts` file with the following

```javascript
// ...
if (testPrivateKey) {
  config.networks = {
    mumbai: createTestnetConfig("mumbai"),
  };
}
```

Finally, run

```bash
  npx hardhat run scripts/deploy/mumbai/protocol.js --network mumbai
```

## Feedback

If you have any feedback, please reach out to us at support@nftlabs.co.

## Authors

- [NFT Labs](https://github.com/nftlabs)

## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)
