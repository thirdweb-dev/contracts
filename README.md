
# Pack Protocol

**Repository redesign ongoing**

This repository contains the core smart contracts for the Pack 
Protocol.

Pack Protocol lets anyone create and sell packs filled with
rewards. A pack can be opened only once. Upon opening a pack, a
reward from the pack is randomly selected and distributed to 
the pack opener.

## Rinkeby Deployments

- `Pack.sol` — [0x6416795AF11336ef33EF7BAd1354F370141f8728](https://rinkeby.etherscan.io/address/0x6416795AF11336ef33EF7BAd1354F370141f8728#code)

- `PackMarket.sol` — [0x5c0Ad93A3580260820fDcD1E5F5fDD714DA800B7](https://rinkeby.etherscan.io/address/0x5c0Ad93A3580260820fDcD1E5F5fDD714DA800B7#code)

- `PackCoin.sol` — [0x49e7f00ee5652523fAdE13674100c8518d7DA8b6](https://rinkeby.etherscan.io/address/0x49e7f00ee5652523fAdE13674100c8518d7DA8b6#code)

## Deployment

To deploy this project on a given network (e.g. rinkeby)

```bash
  npx hardhat run scripts/deploySimple.js --network rinkeby
```

To verify the deployment on Etherscan

```bash
  npx hardhat verify --network rinkeby $contract-address $constructor-args
```

  
## Run Locally

Clone the project

```bash
  git clone https://github.com/nftlabs/pack-protocol.git
```

Go to the project directory

```bash
  cd pack-protocol
```

Install dependencies

```bash
  yarn install
```

Compile contracts

```bash
  npx hardhat compile
```

Run hardhat tests

```bash
  npx hardhat test
```

  
## Feedback

If you have any feedback, please reach out to us at krishang@nftlabs.co

  
## Authors

- [NFT Labs](https://nftlabs.co/)
