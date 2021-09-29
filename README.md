# NFTLabs Protocol

NFTLabs lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments: Access Packs contracts

The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai

- `ProtocolControl.sol`: [0x8bB9B8305543cdF927e22648DC6392b5FF11a38A](https://mumbai.polygonscan.com/address/0x8bB9B8305543cdF927e22648DC6392b5FF11a38A#code)

- `Pack.sol`: [0xDca0089f941b7f8b4f9D818eA51204DB7d3b05f6](https://mumbai.polygonscan.com/address/0xDca0089f941b7f8b4f9D818eA51204DB7d3b05f6#code)

- `Market.sol`: [0xe448A5878866dD47F61C6654Ee297631eEb98966](https://mumbai.polygonscan.com/address/0xe448A5878866dD47F61C6654Ee297631eEb98966#code)

- `AccessNFT.sol`: [0x32e28ac9F548A845C2E62EFA4F32ee6ecB257F4D](https://mumbai.polygonscan.com/address/0x32e28ac9F548A845C2E62EFA4F32ee6ecB257F4D#code)

- `Forwarder.sol`: [0x9B73b547191170e76238c7C24cF75b8653D7Aa82](https://mumbai.polygonscan.com/address/0x9B73b547191170e76238c7C24cF75b8653D7Aa82#code)

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

To use scripts, update the transaction parameters in the particular script (e.g. `packId` in `scripts/txs/openPack.ts`) and run e.g -

```bash
  yarn run openPack --network {network name}
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

To deploy the entire protocol, run

```bash
  yarn run deploy-protocol --network {network name}
```

To deploy `Pack.sol` and `Market.sol` as individual modules, run e.g.

```bash
  yarn run deploy-pack --network {network name}
```

Finally, update the `README.md` files with the new addresses, which can be found in `utils/addresses.json`.

## Verify contracts on Etherscan / Polygonscan

To verify the entire protocol, run

```bash
  yarn run verify-protocol --network {network name}
```

To verify individual modules like `Pack.sol`, run

```bash
  yarn run verify-pack --network {network name}
```

## Feedback

If you have any feedback, please reach out to us at support@nftlabs.co.

## Authors

- [NFT Labs](https://github.com/nftlabs)

## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)
