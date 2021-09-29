# NFTLabs Protocol

NFTLabs lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments

The contracts in the `/contracts` directory are deployed on the following networks.

## Fresh contracts -

### Mumbai

- `ProtocolControl.sol`: [0x75E68Fc66Dc1B7D9fEdde874Daa9f6928De47dAa](https://mumbai.polygonscan.com/address/0x75E68Fc66Dc1B7D9fEdde874Daa9f6928De47dAa#code)

- `Pack.sol`: [0xf86dae2466888981677e8CaB67D50A3D87A06fEC](https://mumbai.polygonscan.com/address/0xf86dae2466888981677e8CaB67D50A3D87A06fEC#code)

- `Market.sol`: [0xAcc2f9F70af22B539a9B38A9880E608cC7583F39](https://mumbai.polygonscan.com/address/0xAcc2f9F70af22B539a9B38A9880E608cC7583F39#code)

- `AccessNFT.sol`: [0x403a9060F8eFE3668b6DBB7746C2476Fe74037cf](https://mumbai.polygonscan.com/address/0x403a9060F8eFE3668b6DBB7746C2476Fe74037cf#code)

- `Forwarder.sol`: [0x717ae3154b0AA1b783544E161F4A95B92B11d830](https://mumbai.polygonscan.com/address/0x717ae3154b0AA1b783544E161F4A95B92B11d830#code)

## Access Packs is using:

### Mumbai

- `ProtocolControl.sol`: [0xE3A652bb9C3e14d883e4F7204799B43DBe0083c7](https://mumbai.polygonscan.com/address/0xE3A652bb9C3e14d883e4F7204799B43DBe0083c7#code)

- `Pack.sol`: [0x3502E335C76Aac3f2d15A4Dd63A2d4a2F10533Fd](https://mumbai.polygonscan.com/address/0x3502E335C76Aac3f2d15A4Dd63A2d4a2F10533Fd#code)

- `Market.sol`: [0x7988037F7ea75e585eD97a81354EA6fbfF0D91F5](https://mumbai.polygonscan.com/address/0x7988037F7ea75e585eD97a81354EA6fbfF0D91F5#code)

- `AccessNFT.sol`: [0x5330157deafbA9B0425e33268de1D5043E09F0c0](https://mumbai.polygonscan.com/address/0x5330157deafbA9B0425e33268de1D5043E09F0c0#code)

- `Forwarder.sol`: [0xE361f049d4A7298dE53Cd431966ECf0de809cdf6](https://mumbai.polygonscan.com/address/0xE361f049d4A7298dE53Cd431966ECf0de809cdf6#code)

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
