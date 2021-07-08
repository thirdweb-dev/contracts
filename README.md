# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `ControlCenter.sol`: [0xafB82b9036345De038771B8B01E6A76eBc01E1FC](https://rinkeby.etherscan.io/address/0xafB82b9036345De038771B8B01E6A76eBc01E1FC#code)

- `Pack.sol`: [0x982Fe0d70Da1BEaa396778830ACcF19062c83a6E](https://rinkeby.etherscan.io/address/0x982Fe0d70Da1BEaa396778830ACcF19062c83a6E#code)

- `Handler.sol`: [0xE0c4F0058f339Ac5881ad1FDcfdF3a16190E94Eb](https://rinkeby.etherscan.io/address/0xE0c4F0058f339Ac5881ad1FDcfdF3a16190E94Eb#code)

- `Market.sol`: [0x4e894D3664648385f18D6497bdEaC0574F91B48B](https://rinkeby.etherscan.io/address/0x4e894D3664648385f18D6497bdEaC0574F91B48B#code)

- `RNG.sol`: [0x302506376b143D368f84863652E1508D38931696](https://rinkeby.etherscan.io/address/0x302506376b143D368f84863652E1508D38931696#code)

- `AssetSafe.sol`: [0xFd257547e15F9101D33173F4D062a237C2Db1B07](https://rinkeby.etherscan.io/address/0xFd257547e15F9101D33173F4D062a237C2Db1B07#code)

- `AccessPacks.sol`: [0xB98C0E788fb82297a73E32296e246653390eCE68](https://rinkeby.etherscan.io/address/0xB98C0E788fb82297a73E32296e246653390eCE68#code)

## Run Locally

Clone the project

```bash
  git clone https://github.com/nftlabs/pack-protocol.git
```

Install dependencies

```bash
  yarn install
```

Run tests by running

```bash
  npx hardhat test
```
  
## Deployment

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
  npx hardhat verify --network rinkeby $contract-address $constructor-args
```
  
## Feedback

If you have any feedback, please reach out to us at support@nftlabs.co

## Authors

- [NFT Labs](https://github.com/nftlabs)

  
## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)