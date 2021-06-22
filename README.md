# $Pack Protocol

The $PACK Protocol wraps arbitrary assets (ERC20, ERC721, ERC1155 tokens) into packs (or ERC 1155 'pack tokens'). 
These packs can be airdropped or sold. 

Combinations of the wrapped assets in the pack are assigned rarity. Opening 
a pack distributes one of those combinations of the wrapped assets to the pack opener. 
The combination distributed is chosen *randomly*.

## Architecture
`PackControl.sol` is the master contract / control center of the protocol. It allows the protocol admin
to perform CRUD operations on different modules of the contract. Updgrading the control
center requires an overhaul of the protocol.

`PackERC1155.sol` is a core module of the protocol, and is explicitly
defined in control center.

Secondary modules like `Pack.sol` and `PackMarket.sol` perform for the distribution
and sale of ERC1155 pack tokens.


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

To deploy this project on a given network (e.g. mainnet) update your hardhat config file
with the following

```javascript
module.exports = {
  solidity: "0.8.0",
  networks: {
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${TEST_PRIVATE_KEY}`]
    }
  }
};
```

Finally, run 

```bash
  npx hardhat run scripts/deploySimple.js --network mainnet
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