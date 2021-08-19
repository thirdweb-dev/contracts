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
- `ProtocolControl.sol`: [0x932a80d12133daDa78d1eFeAa69C53f35b7717eB](https://mumbai.polygonscan.com/address/0x932a80d12133daDa78d1eFeAa69C53f35b7717eB#code)

- `Pack.sol`: [0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150](https://mumbai.polygonscan.com/address/0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150#code)

- `Market.sol`: [0x420dF8F7659cad7b9701b882E5A0f0282c49907d](https://mumbai.polygonscan.com/address/0x420dF8F7659cad7b9701b882E5A0f0282c49907d#code)

- `Rewards.sol`: [0xe9559e34a8A32FA8Dc050fAaFD9343B666BC92CF](https://mumbai.polygonscan.com/address/0xe9559e34a8A32FA8Dc050fAaFD9343B666BC92CF#code)

### Rinkeby

- `ProtocolControl.sol`: [0x916a0c502Ea07B50e48c5c5D6e6C5e26E6F04e02](https://rinkeby.etherscan.io/address/0x916a0c502Ea07B50e48c5c5D6e6C5e26E6F04e02#code)

- `Pack.sol`: [0xcD6c2E7439C712464B8D49DD6369C976894EbAdb](https://rinkeby.etherscan.io/address/0xcD6c2E7439C712464B8D49DD6369C976894EbAdb#code)

- `Market.sol`: [0x87Fe40CAC2Ba4b2d8d5639Ea712Bab6C294e5454](https://rinkeby.etherscan.io/address/0x87Fe40CAC2Ba4b2d8d5639Ea712Bab6C294e5454#code)

- `Rewards.sol`: [0x906f3c4643F0C721eB48A40d3903043B43C43434](https://rinkeby.etherscan.io/address/0x906f3c4643F0C721eB48A40d3903043B43C43434#code)

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