# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `ProtocolControl.sol`: [0x653CB7AA740f17116Ab709e0f2bD6Db4941f5855](https://rinkeby.etherscan.io/address/0x653CB7AA740f17116Ab709e0f2bD6Db4941f5855#code)

- `Pack.sol`: [0x22B9fdC2fCeE92675Ab9398F42251A6A2cd8f7A1](https://rinkeby.etherscan.io/address/0x22B9fdC2fCeE92675Ab9398F42251A6A2cd8f7A1#code)

- `Market.sol`: [0x908dF092CDa0a3c6D7326F483113fcFc0BF892f8](https://rinkeby.etherscan.io/address/0x908dF092CDa0a3c6D7326F483113fcFc0BF892f8#code)

- `RNG.sol`: [0x65D5D86562A478F1EbdB9b45b8E27179Bfd1A9df](https://rinkeby.etherscan.io/address/0x65D5D86562A478F1EbdB9b45b8E27179Bfd1A9df#code)

- `Rewards.sol`: [0x87e54ac75a7f29dfB763Db4D752749E01E308c10](https://rinkeby.etherscan.io/address/0x87e54ac75a7f29dfB763Db4D752749E01E308c10#code)

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
  npx hardhat run scripts/txs/${testFileName}.ts --network rinkeby
```
  
## Deploying contracts

To deploy this project on a given network (e.g. rinkeby) update the `hardhat.config.ts` file with the following

```javascript
// ...
if (testPrivateKey) {
  config.networks = {
    rinkeby: createTestnetConfig("rinkeby"),
  };
}
```

Finally, run 

```bash
  npx hardhat run scripts/deploySimple.js --network rinkeby
```

To verify the deployment on Etherscan

```bash
  npx hardhat verify --network rinkeby ${contract-address} ${constructor-args}
```
  
## Feedback

If you have any feedback, please reach out to us at support@nftlabs.co

## Authors

- [NFT Labs](https://github.com/nftlabs)

  
## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)