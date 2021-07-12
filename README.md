# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `ControlCenter.sol`: [0xBF0f4Dc9B3E59a3bF69685D3cE8a04D78675c255](https://rinkeby.etherscan.io/address/0xBF0f4Dc9B3E59a3bF69685D3cE8a04D78675c255#code)

- `Pack.sol`: [0x3A6701A5D1cb6Cd2A8886aFFeE3012E2396bA755](https://rinkeby.etherscan.io/address/0x3A6701A5D1cb6Cd2A8886aFFeE3012E2396bA755#code)

- `Handler.sol`: [0x87a041FFdf941a305d8d0A581080972ff8e1Fd42](https://rinkeby.etherscan.io/address/0x87a041FFdf941a305d8d0A581080972ff8e1Fd42#code)

- `Market.sol`: [0xDd8C26Bb12dc8cC31E572Cc8e83919c4d02fad5e](https://rinkeby.etherscan.io/address/0xDd8C26Bb12dc8cC31E572Cc8e83919c4d02fad5e#code)

- `RNG.sol`: [0x38FCAa08CC0ADcFEcfc8488EeB49f67Ab58E4A9A](https://rinkeby.etherscan.io/address/0x38FCAa08CC0ADcFEcfc8488EeB49f67Ab58E4A9A#code)

- `AssetSafe.sol`: [0x9b6962a5a1Bc2E1Fa0508fe933310B51FC6063e1](https://rinkeby.etherscan.io/address/0x9b6962a5a1Bc2E1Fa0508fe933310B51FC6063e1#code)

- `AccessPacks.sol`: [0x16611A37a86B7C35b2d5C316402Ecc24f18B36e2](https://rinkeby.etherscan.io/address/0x16611A37a86B7C35b2d5C316402Ecc24f18B36e2#code)

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
    mainnet: createTestnetConfig("rinkeby"),
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