<p align="center">
<br />
<a href="https://thirdweb.com"><img src="https://github.com/thirdweb-dev/typescript-sdk/blob/main/logo.svg?raw=true" width="200" alt=""/></a>
<br />
</p>
<h1 align="center">thirdweb Contracts</h1>
<p align="center">
<a href="https://www.npmjs.com/package/@thirdweb-dev/contracts"><img src="https://img.shields.io/npm/v/@thirdweb-dev/contracts?color=red&logo=npm" alt="npm version"/></a>
<a href="https://github.com/thirdweb-dev/contracts/actions"><img alt="Build Status" src="https://github.com/thirdweb-dev/contracts/actions/workflows/tests.yml/badge.svg"/></a>
<a href="https://discord.gg/thirdweb"><img alt="Join our Discord!" src="https://img.shields.io/discord/834227967404146718.svg?color=7289da&label=discord&logo=discord&style=flat"/></a>

</p>
<p align="center"><strong>Collection of smart contracts deployable via the thirdweb SDK, dashboard and CLI</strong></p>
<br />

## Installation

```shell
npm i @thirdweb-dev/contracts
```

## Running Tests

1. `yarn`: install contracts dependencies
2. `forge install`: install tests dependencies
3. `forge test`: run the tests

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

## Pre-built Contracts

Pre-built contracts are written by the thirdweb team, and cover the most common use cases for smart contracts.

Release pages for pre-built contracts:

- [DropERC20](https://thirdweb.com/deployer.thirdweb.eth/DropERC20)
- [DropERC721](https://thirdweb.com/deployer.thirdweb.eth/DropERC721)
- [DropERC1155](https://thirdweb.com/deployer.thirdweb.eth/DropERC1155)
- [SignatureDrop](https://thirdweb.com/deployer.thirdweb.eth/SignatureDrop)
- [Marketplace](https://thirdweb.com/deployer.thirdweb.eth/Marketplace)
- [Multiwrap](https://thirdweb.com/deployer.thirdweb.eth/Multiwrap)
- [TokenERC20](https://thirdweb.com/deployer.thirdweb.eth/TokenERC20)
- [TokenERC721](https://thirdweb.com/deployer.thirdweb.eth/TokenERC721)
- [TokenERC1155](https://thirdweb.com/deployer.thirdweb.eth/TokenERC1155)
- [VoteERC20](https://thirdweb.com/deployer.thirdweb.eth/VoteERC20)
- [Split](https://thirdweb.com/deployer.thirdweb.eth/Split)

[Learn more about pre-built contracts](https://portal.thirdweb.com/pre-built-contracts)

## Extensions

Extensions are building blocks that help enrich smart contracts with features.

Some blocks come packaged together as Base Contracts, which come with a full set of features out of the box that you can modify and extend. These contracts are available at `contracts/base/`.

Other (smaller) blocks are Features, which provide a way for you to pick and choose which individual pieces you want to put into your contract; with full customization of how those features work. These are available at `contracts/extension/`.

[Learn more about extensions](https://portal.thirdweb.com/extensions)

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


## Contract Audits
- [Audit 1](https://ipfs.io/ipfs/QmNgNaLwzgMxcx9r6qDvJmTFam6xxUxX7Vp8E99oRt7i74)
- [Audit 2](https://ipfs.io/ipfs/QmWfueeKQrggrVQNjWkF4sYJECp56vNnuAXCPVecFFKz2j)
- [Audit 3](https://gateway.ipfscdn.io/ipfs/QmfKqeUfUgNwFn5B1fUAxzikj89mneZEETKrF7JfaJg5St/)
- [Audit 4](https://gateway.ipfscdn.io/ipfs/QmaMiezCMfmo5zWmwNc2WXLex11BuRZJ9p9ZhWj638Tdws/)
- [Audit 5](https://gateway.ipfscdn.io/ipfs/QmSiyyHkL9fyYdBqb81Dm1Yb3HvuxLfunkArADKFk3WDKY)
- [Audit 6](https://gateway.ipfscdn.io/ipfs/QmWcGjVt5bQiJCJHQYgMj24qRkHwxqsyVMTcU23zBptC26)
- [Audit 7](https://gateway.ipfscdn.io/ipfs/QmWhvM4QBrs56EXLNRfW9rQ2izJ7JEzDTxDrWsFjLMi8DE)
- [Audit 8](https://gateway.ipfscdn.io/ipfs/QmdawSEzMAvKGfjbeBZAW3sgXuh2jSVhcKwfqNpmiPTsrX)
- [Audit 9](https://gateway.ipfscdn.io/ipfs/QmSKcP4cHyp1xP9RXkC84UwD6ugsotRAZqBy98WTjxnWwP)
- [Audit 10](https://gateway.ipfscdn.io/ipfs/QmRoNX9uePGnjPiwxUzzEXscR2MaTeDy2RmoMHoSGCQk7Y)
- [Audit 11](https://ipfs.thirdwebcdn.com/ipfs/QmYmWWwSnpEjZm4wTvvyUJ6QfBVXrtKCCnQoxa2cWAAJ8Z)
- [Audit 12](https://ipfs-2.thirdwebcdn.com/ipfs/QmXWSH7X8CGe4Q3tfw3MAnCinyU5WKLDy45bRBCSSrritB/)

## Bug reports

Found a security issue with our smart contracts? Send bug reports to security@thirdweb.com and we'll continue communicating with you from there. We're actively developing a bug bounty program; bug report payouts happen on a case by case basis, for now.

## Feedback

If you have any feedback, please reach out to us at support@thirdweb.com.

## Authors

- [thirdweb](https://thirdweb.com)

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt)
