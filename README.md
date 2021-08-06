# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai
- `ProtocolControl.sol`: [0x312c3Dd6E0102F872535c3618Ae2Fb3D68C8C087](https://mumbai.polygonscan.com/address/0x312c3Dd6E0102F872535c3618Ae2Fb3D68C8C087#code)

- `Pack.sol`: [0x9C90C6073Cefd64055e4fc6AB9E8127e1a2b44F3](https://mumbai.polygonscan.com/address/0x9C90C6073Cefd64055e4fc6AB9E8127e1a2b44F3#code)

- `Market.sol`: [0x1C86CC9D4C79486571B465eB98ee7De8260BDBE6](https://mumbai.polygonscan.com/address/0x1C86CC9D4C79486571B465eB98ee7De8260BDBE6#code)

- `Rewards.sol`: [0xF0D1064ec8Dee772af45D6e9E45Cfa5F429d80a7](https://mumbai.polygonscan.com/address/0xF0D1064ec8Dee772af45D6e9E45Cfa5F429d80a7#code)

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
  npx hardhat run scripts/.../${testFileName}.ts --network mumbai
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
  npx hardhat run scripts/deploySimple.js --network mumbai
```
  
## Feedback

If you have any feedback, please reach out to us at support@nftlabs.co

## Authors

- [NFT Labs](https://github.com/nftlabs)

  
## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)