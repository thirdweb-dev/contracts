# $Pack Protocol

The $PACK Protocol wraps arbitrary assets (ERC20, ERC721, ERC1155 tokens) into ERC 1155 reward tokens. Combinations of these reward
tokens are bundled into ERC 1155 pack tokens. Opening a pack distributes a reward randomly selected from the pack to the opener. Both
pack and reward tokens can be airdropped or sold.

## Architecture
`PackControl.sol` is the master contract / control center of the protocol. It allows the protocol admin to perform CRUD operations on 
different modules of the contract. Updgrading the control center requires an overhaul of the protocol.

`PackERC1155.sol` is a core module of the protocol, and is explicitly defined in control center.

Secondary modules like `Pack.sol` and `PackMarket.sol` perform for the distribution and sale of ERC1155 pack and reward tokens.

## Deployments
The contracts in the `/contracts` directory are deployed on the following networks.

### Rinkeby
- `PackControl.sol`: [0x481A7Fe771F671fE8a1A4ff4362D28Fd72c042B7](https://rinkeby.etherscan.io/address/0x481A7Fe771F671fE8a1A4ff4362D28Fd72c042B7#code)

- `PackERC1155.sol`: [0xe280e8BcCF8dD8070B079b6b62d6d4ea3CD992A7](https://rinkeby.etherscan.io/address/0xe280e8BcCF8dD8070B079b6b62d6d4ea3CD992A7#code)

- `DexRNG.sol`: [0x1F648fFdDC74b9f1c273B92F2d0D9F8a3F1c844E](https://rinkeby.etherscan.io/address/0x1F648fFdDC74b9f1c273B92F2d0D9F8a3F1c844E#code)

- `PackHandler.sol`: [0xF0FC15174DB513CE2AbD3F949Cd5F6621D094082](https://rinkeby.etherscan.io/address/0xF0FC15174DB513CE2AbD3F949Cd5F6621D094082#code)

- `PackMarket.sol`: [0x99C91C3E968367610a1Afe0DeA58048094031f92](https://rinkeby.etherscan.io/address/0x99C91C3E968367610a1Afe0DeA58048094031f92#code)

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