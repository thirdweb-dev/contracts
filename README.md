# NFTLabs Protocol

NFTLabs lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments: Access Packs contracts

The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai

- `ProtocolControl.sol`: [0x53975617f305fA0e6f29fd0870C32ad38ee6bD70](https://mumbai.polygonscan.com/address/0x53975617f305fA0e6f29fd0870C32ad38ee6bD70#code)

- `Pack.sol`: [0x1b2812ba4fD7eCdfE357e93749d31B6C86B8063d](https://mumbai.polygonscan.com/address/0x1b2812ba4fD7eCdfE357e93749d31B6C86B8063d#code)

- `Market.sol`: [0x66c132Fcd9bE13C48821486e27Dc19146056c3a1](https://mumbai.polygonscan.com/address/0x66c132Fcd9bE13C48821486e27Dc19146056c3a1#code)

- `AccessNFT.sol`: [0xB056F10C3c44809c39B447462E48130d288FCc59](https://mumbai.polygonscan.com/address/0xB056F10C3c44809c39B447462E48130d288FCc59#code)

- `Forwarder.sol`: [0x074048E2A7Df00F32563e7448A50769aAe735948](https://mumbai.polygonscan.com/address/0x074048E2A7Df00F32563e7448A50769aAe735948#code)

- `NFTWrapper.sol`: [0x873c3e90f0dE5712FC0f5DDba2c4a08Ec4C40c36](https://mumbai.polygonscan.com/address/0x873c3e90f0dE5712FC0f5DDba2c4a08Ec4C40c36#code)

## Test helper contracts

### Mumbai

- `MintableERC20Permit.sol`: [0xCe8271Ad06e8CB0EE47d1486947313b7c1290D14](https://mumbai.polygonscan.com/address/0xCe8271Ad06e8CB0EE47d1486947313b7c1290D14#code)

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
