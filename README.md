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

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai
- `ProtocolControl.sol`: [0x3d86dD9846c0a15B0f40037AAf51CC68A4236add](https://mumbai.polygonscan.com/address/0x3d86dD9846c0a15B0f40037AAf51CC68A4236add#code)

- `Pack.sol`: [0xD89eE4F34BC76315E77D808305c0931f28Fa3C5D](https://mumbai.polygonscan.com/address/0xD89eE4F34BC76315E77D808305c0931f28Fa3C5D#code)

- `Market.sol`: [0xD521909301724a02E0C66599Dfb5A47d4390fc43](https://mumbai.polygonscan.com/address/0xD521909301724a02E0C66599Dfb5A47d4390fc43#code)

- `Rewards.sol`: [0x7c6c7048Cd447BA200bde9A89A2ECc83435b7E51](https://mumbai.polygonscan.com/address/0x7c6c7048Cd447BA200bde9A89A2ECc83435b7E51#code)

### Rinkeby

- `ProtocolControl.sol`: [0xAFe8f8EDad3Fd7b0108997b51CCd24286FbF000B](https://rinkeby.etherscan.io/address/0xAFe8f8EDad3Fd7b0108997b51CCd24286FbF000B#code)

- `Pack.sol`: [0x928C9EE38048e5D0A4601D1FDcF7B9E57317278D](https://rinkeby.etherscan.io/address/0x928C9EE38048e5D0A4601D1FDcF7B9E57317278D#code)

- `Market.sol`: [0x92902EF66B71a4646d3B33FD16ffC7EaD0182faC](https://rinkeby.etherscan.io/address/0x92902EF66B71a4646d3B33FD16ffC7EaD0182faC#code)

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

If you have any feedback, please reach out to us at support@nftlabs.co

## Authors

- [NFT Labs](https://github.com/nftlabs)

  
## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)