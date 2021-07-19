# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `ProtocolControl.sol`: [0xb08E08f4B0A88eaFc1446e703390Ad49dB7507e8](https://rinkeby.etherscan.io/address/0xb08E08f4B0A88eaFc1446e703390Ad49dB7507e8#code)

- `Pack.sol`: [0x5ECC47810De05F49728Abe629f59FF020D4b5d92](https://rinkeby.etherscan.io/address/0x5ECC47810De05F49728Abe629f59FF020D4b5d92#code)

- `Market.sol`: [0x9e3880045597a3eaAfB1E1589Ea2711efc5B252d](https://rinkeby.etherscan.io/address/0x9e3880045597a3eaAfB1E1589Ea2711efc5B252d#code)

- `RNG.sol`: [0xc0afa9B5F59830EA4921D5789A403b3724a2334C](https://rinkeby.etherscan.io/address/0xc0afa9B5F59830EA4921D5789A403b3724a2334C#code)

- `Rewards.sol`: [0xD3207F46a7C1ABf8bF22E43056521B9d22758E65](https://rinkeby.etherscan.io/address/0xD3207F46a7C1ABf8bF22E43056521B9d22758E65#code)

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