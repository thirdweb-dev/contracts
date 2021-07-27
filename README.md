# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `ProtocolControl.sol`: [0xA0dd9C617a941de9B044C43f330aA0B9F2111CAf](https://rinkeby.etherscan.io/address/0xA0dd9C617a941de9B044C43f330aA0B9F2111CAf#code)

- `Pack.sol`: [0x69b014f52059127f0119e9e1Ab5E3c60f4A5FF58](https://rinkeby.etherscan.io/address/0x69b014f52059127f0119e9e1Ab5E3c60f4A5FF58#code)

- `Market.sol`: [0x49ae606B0AC72D744C6A84C3Cf0e8c29aB8a3db5](https://rinkeby.etherscan.io/address/0x49ae606B0AC72D744C6A84C3Cf0e8c29aB8a3db5#code)

- `RNG.sol`: [0xF53dFc5B65c5C8712235A1ee81e18fb021ebCC0f](https://rinkeby.etherscan.io/address/0xF53dFc5B65c5C8712235A1ee81e18fb021ebCC0f#code)

- `Rewards.sol`: [0x32E94dfd93D9a409572561B1D54cda229d61B051](https://rinkeby.etherscan.io/address/0x32E94dfd93D9a409572561B1D54cda229d61B051#code)

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