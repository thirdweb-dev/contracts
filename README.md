# Thirdweb Contracts

> Looking for version 1? Click [here](https://github.com/thirdweb-dev/contracts/tree/v1)!

## Quick start

The [`@thirdweb-dev/contracts`](https://www.npmjs.com/package/@thirdweb-dev/contracts) package gives you access to all contracts and interfaces available in the `/contracts` directory of this repository.

**Installation:**
```bash
yarn add @thirdweb-dev/contracts
```

**Usage**
`@thirdweb-dev/contracts` can be used in your Solidity project just like other popular libraries like `@openzeppelin/contracts`. Once you've installed the package, import the relevant resources from the package as follows:

```solidity
// Example usage

import "@thirweb-dev/contracts/contracts/interfaces/token/TokenERC721.sol";

contract MyNFT is TokenERC721 { ... }
```

## Run locally

Clone the repository:
```bash
git clone https://github.com/thirdweb-dev/contracts.git
```

This repository is a hybrid [hardhat](https://hardhat.org/) and [forge](https://github.com/foundry-rs/foundry/tree/master/forge) project.

First install the relevant dependencies of the project:
```bash
yarn

forge install
```

To compile contracts, run:
```bash
forge build
```

Or, if you prefer hardhat, you can run:
```bash
npx hardhat compile
```


To run tests:
```bash
forge test
```

To export the ABIs of the coontracts in the `/contracts` directory, run:
```
npx hardhat export-abi
```

To run any scripts in the `/scripts` directory, run:
```
npx hardhat run scripts/{path to the script}
```

## Deployments

The thirdweb registry (`TWRegistry`) and factory (`TWFactory`) have been deployed on the following chains:
[
    Ethereum mainnet,
    Rinkeby,
    Goerli,
    Polygon mainnet,
    Mumbai (Polygon testnet)
    Avalanche mainnet,
    Avalanche testnet,
    Fantom mainnet,
    Fantom testnet
]

- `TWRegistry`: [0x7c487845f98938Bb955B1D5AD069d9a30e4131fd](https://blockscan.com/address/0x7c487845f98938Bb955B1D5AD069d9a30e4131fd) (same address for all mentioned networks)

- `TWFactory`: [0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0](https://blockscan.com/address/0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0) (same address for all mentioned networks, except Fantom mainnet)
  
- `TWFactory`: [0x97EA0Fcc552D5A8Fb5e9101316AAd0D62Ea0876B](https://blockscan.com/address/0x97EA0Fcc552D5A8Fb5e9101316AAd0D62Ea0876B) (address for Fantom mainnet)

## Feedback

If you have any feedback, please reach out to us at support@thirdweb.com.

## Authors

- [thirdweb](https://thirdweb.com)

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt)
