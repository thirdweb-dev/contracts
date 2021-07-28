# $Pack Protocol

$PACK Protocol lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward 
from the pack is distributed to the pack opener.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai
- `ProtocolControl.sol`: [0x394F760b187Ca06431F10DC24400ae5c8fa645f0](https://mumbai.polygonscan.com/address/0x394F760b187Ca06431F10DC24400ae5c8fa645f0#code)

- `Pack.sol`: [0x06e17322326f6ed715BEFc35F53e5EEA01836cB8](https://mumbai.polygonscan.com/address/0x06e17322326f6ed715BEFc35F53e5EEA01836cB8#code)

- `Market.sol`: [0x15beB4eEb99AbCB94aF60AFFC2fE4D3C41e77890](https://mumbai.polygonscan.com/address/0x15beB4eEb99AbCB94aF60AFFC2fE4D3C41e77890#code)

- `RNG.sol`: [0x95196b3Cf1Cd1e007bA3b12CF2794A2aB0ef53d6](https://mumbai.polygonscan.com/address/0x95196b3Cf1Cd1e007bA3b12CF2794A2aB0ef53d6#code)

- `Rewards.sol`: [0xF3cD296A5a120FC8043E0e24C0e7857C24c29143](https://mumbai.polygonscan.com/address/0xF3cD296A5a120FC8043E0e24C0e7857C24c29143#code)

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