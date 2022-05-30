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

## Deployed addresses

### Production

- `TWRegistry`: [0x7c487845f98938Bb955B1D5AD069d9a30e4131fd](https://blockscan.com/address/0x7c487845f98938Bb955B1D5AD069d9a30e4131fd)

- `TWFactory`: [0x11c34F062Cb10a20B9F463E12Ff9dA62D76FDf65](https://blockscan.com/address/0x11c34F062Cb10a20B9F463E12Ff9dA62D76FDf65)

### Dev - (Mumbai only)

- `TWRegistry`: [0x3F17972CB27506eb4a6a3D59659e0B57a43fd16C](https://blockscan.com/address/0x3F17972CB27506eb4a6a3D59659e0B57a43fd16C#code)

- `ByocRegistry`: [0x61Bb02795b4fF5248169A54D9f149C4557B0B7de](https://mumbai.polygonscan.com/address/0x61Bb02795b4fF5248169A54D9f149C4557B0B7de#code)

- `ByocFactory`: [0x3c3D901Acb5f7746dCf06B26fCe881d21970d2B6](https://mumbai.polygonscan.com/address/0x3c3D901Acb5f7746dCf06B26fCe881d21970d2B6#code)

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
