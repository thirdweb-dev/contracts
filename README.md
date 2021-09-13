# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments

The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai

- `ProtocolControl.sol`: [0x9d7DDC9585a6C24bb2fA7980D825e6830A402753](https://mumbai.polygonscan.com/address/0x9d7DDC9585a6C24bb2fA7980D825e6830A402753#code)

- `Pack.sol`: [0xb82d2f432A489b629f5574Bc7FcDEa4a9D2a9a99](https://mumbai.polygonscan.com/address/0xb82d2f432A489b629f5574Bc7FcDEa4a9D2a9a99#code)

- `Market.sol`: [0xC0C872a7eBCDA2c206B76CCAF7546d4f22642e8b](https://mumbai.polygonscan.com/address/0xC0C872a7eBCDA2c206B76CCAF7546d4f22642e8b#code)

- `Rewards.sol`: [0xb9943602a34987535440AE49c12A921C26Ac9e77](https://mumbai.polygonscan.com/address/0xb9943602a34987535440AE49c12A921C26Ac9e77#code)

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
