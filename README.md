# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `ProtocolControl.sol`: [0x278f941f4d167E6f75f7607c6ff12d86a2757568](https://rinkeby.etherscan.io/address/0x278f941f4d167E6f75f7607c6ff12d86a2757568#code)

- `Pack.sol`: [0xe3c195AeCFefE42c4f5B2332dcd635930cBB494e](https://rinkeby.etherscan.io/address/0xe3c195AeCFefE42c4f5B2332dcd635930cBB494e#code)

- `Market.sol`: [0x3C5dDEd0160d4cef316138F21b7Cb0B0A77bBf50](https://rinkeby.etherscan.io/address/0x3C5dDEd0160d4cef316138F21b7Cb0B0A77bBf50#code)

- `RNG.sol`: [0x6782e28dC7009DeFea4B7506A8c9ecA9Fd927e47](https://rinkeby.etherscan.io/address/0x6782e28dC7009DeFea4B7506A8c9ecA9Fd927e47#code)

- `Rewards.sol`: [0xc36BEd3Ae0ff500F2D2E918Df90B4d59DFAE9942](https://rinkeby.etherscan.io/address/0xc36BEd3Ae0ff500F2D2E918Df90B4d59DFAE9942#code)

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