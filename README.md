# Thirdweb Contracts

> Looking for version 1? Click [here](https://github.com/thirdweb-dev/contracts/tree/v1)!

## Quick start

The [`@thirdweb-dev/contracts`](https://www.npmjs.com/package/@thirdweb-dev/contracts) package gives you access to all contracts and interfaces available in the `/contracts` directory of this repository.

**Installation:**
```bash
yarn add @thirdweb-dev/contracts
```

**Usage:**

`@thirdweb-dev/contracts` can be used in your Solidity project just like other popular libraries e.g. `@openzeppelin/contracts`. Once you've installed the package, import the relevant resources from the package as follows:

```solidity
// Example usage

import "@thirdweb-dev/contracts/contracts/interfaces/token/TokenERC721.sol";

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

To export the ABIs of the contracts in the `/contracts` directory, run:
```
npx hardhat export-abi
```

To run any scripts in the `/scripts` directory, run:
```
npx hardhat run scripts/{path to the script}
```

## Deployments

The thirdweb registry (`TWRegistry`) and factory (`TWFactory`) have been deployed on the following chains:
- [Ethereum mainnet](https://etherscan.io/)
- [Rinkeby](https://rinkeby.etherscan.io/)
- [Goerli](https://goerli.etherscan.io/)
- [Polygon mainnet](https://polygonscan.com/)
- [Polygon Mumbai testnet](https://mumbai.polygonscan.com/)
- [Avalanche mainnet](https://snowtrace.io/)
- [Avalanche Fuji testnet](https://testnet.snowtrace.io/)
- [Fantom mainnet](https://ftmscan.com/)
- [Fantom testnet](https://testnet.ftmscan.com/)

`TWRegistry` is deployed to a common address on all mentioned networks. `TWFactory` is deployed to a common address on all mentioned networks except Fantom mainnet.

- `TWRegistry`: [0x7c487845f98938Bb955B1D5AD069d9a30e4131fd](https://blockscan.com/address/0x7c487845f98938Bb955B1D5AD069d9a30e4131fd)

- `TWFactory`: [0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0](https://blockscan.com/address/0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0)
  
- `TWFactory` (Fantom mainnet): [0x97EA0Fcc552D5A8Fb5e9101316AAd0D62Ea0876B](https://blockscan.com/address/0x97EA0Fcc552D5A8Fb5e9101316AAd0D62Ea0876B)

## Feedback

If you have any feedback, please reach out to us at support@thirdweb.com.

## Authors

- [thirdweb](https://thirdweb.com)

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt)
