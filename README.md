# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai
- `ProtocolControl.sol`: [0x932a80d12133daDa78d1eFeAa69C53f35b7717eB](https://mumbai.polygonscan.com/address/0x932a80d12133daDa78d1eFeAa69C53f35b7717eB#code)

- `Pack.sol`: [0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150](https://mumbai.polygonscan.com/address/0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150#code)

- `Market.sol`: [0xc8035e0347A9182E6d9973e8B081b166Bb8F075a](https://mumbai.polygonscan.com/address/0xc8035e0347A9182E6d9973e8B081b166Bb8F075a#code)

- `Rewards.sol`: [0xe9559e34a8A32FA8Dc050fAaFD9343B666BC92CF](https://mumbai.polygonscan.com/address/0xe9559e34a8A32FA8Dc050fAaFD9343B666BC92CF#code)

### Rinkeby

- `ProtocolControl.sol`: [0x916a0c502Ea07B50e48c5c5D6e6C5e26E6F04e02](https://rinkeby.etherscan.io/address/0x916a0c502Ea07B50e48c5c5D6e6C5e26E6F04e02#code)

- `Pack.sol`: [0xcD6c2E7439C712464B8D49DD6369C976894EbAdb](https://rinkeby.etherscan.io/address/0xcD6c2E7439C712464B8D49DD6369C976894EbAdb#code)

- `Market.sol`: [0xA4377C877dABc47bcCA5D68A182907fC833ef7f4](https://rinkeby.etherscan.io/address/0xA4377C877dABc47bcCA5D68A182907fC833ef7f4#code)

- `Rewards.sol`: [0x906f3c4643F0C721eB48A40d3903043B43C43434](https://rinkeby.etherscan.io/address/0x906f3c4643F0C721eB48A40d3903043B43C43434#code)

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

If you have any feedback, please reach out to us at support@nftlabs.co

## Authors

- [NFT Labs](https://github.com/nftlabs)

  
## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)