# NFTLabs Protocol

NFTLabs lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments: Access Packs contracts

The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai

- `Registry.sol`: [0x5665e52Ed893891F44e0fFE67c40F29074d81a6B](https://mumbai.polygonscan.com/address/0x5665e52Ed893891F44e0fFE67c40F29074d81a6B#code)

- `ProtocolControl.sol`: [0xea68422Cee517E2D5a702fA43cd891a8e3EDd7d7](https://mumbai.polygonscan.com/address/0xea68422Cee517E2D5a702fA43cd891a8e3EDd7d7#code)

- `Pack.sol`: [0x60734D85eD65641Cc20de6cC87e589e367876748](https://mumbai.polygonscan.com/address/0x60734D85eD65641Cc20de6cC87e589e367876748#code)

- `Market.sol`: [0x005b59d38EB1b76412bCe0BA37c45128EEbda362](https://mumbai.polygonscan.com/address/0x005b59d38EB1b76412bCe0BA37c45128EEbda362#code)

- `AccessNFT.sol`: [0xE8cBcE800dcc6C2957626732e808E1833052DCEE](https://mumbai.polygonscan.com/address/0xE8cBcE800dcc6C2957626732e808E1833052DCEE#code)

- `Forwarder.sol`: [0x4B649d0f9E8B00Df56E339C09939A8A15e55f264](https://mumbai.polygonscan.com/address/0x4B649d0f9E8B00Df56E339C09939A8A15e55f264#code)

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
