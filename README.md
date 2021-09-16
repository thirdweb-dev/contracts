# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments

The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai

- `ProtocolControl.sol`: [0x1d169c30b6b2606878b319327e2C0E7529141f71](https://mumbai.polygonscan.com/address/0x1d169c30b6b2606878b319327e2C0E7529141f71#code)

- `Pack.sol`: [0x0c56B393043CDA7c726c27FdD64Bd9262428515F](https://mumbai.polygonscan.com/address/0x0c56B393043CDA7c726c27FdD64Bd9262428515F#code)

- `Market.sol`: [0xe2A8acC6D641b7D2b5922cB90969D0B6B76d689E](https://mumbai.polygonscan.com/address/0xe2A8acC6D641b7D2b5922cB90969D0B6B76d689E#code)

- `Rewards.sol`: [0xEe63992e7AaE8578E7239991960F7494F8dFF005](https://mumbai.polygonscan.com/address/0xEe63992e7AaE8578E7239991960F7494F8dFF005#code)

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
