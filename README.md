# NFTLabs Protocol

NFTLabs lets anyone create and sell packs filled with rewards. A pack can be opened only once. On opening a pack, a reward
from the pack is distributed to the pack opener.

## Deployments: Access Packs contracts

The contracts in the `/contracts` directory are deployed on the following networks.

### Mumbai

- `ProtocolControl.sol`: [0xe5c05a42478591516E6fd92B8D4d7812BC7a6166](https://mumbai.polygonscan.com/address/0xe5c05a42478591516E6fd92B8D4d7812BC7a6166#code)

- `Pack_PL.sol`: [0xf159C4052c9D846881E2e8D76e864bD56C20260b](https://mumbai.polygonscan.com/address/0xf159C4052c9D846881E2e8D76e864bD56C20260b#code)

- `Market.sol`: [0x6c8F185EB8Ba93d30B2976D03DCA496D51A7ED21](https://mumbai.polygonscan.com/address/0x6c8F185EB8Ba93d30B2976D03DCA496D51A7ED21#code)

- `AccessNFT_PL.sol`: [0x5Eac339651C18012238a3F89f63F70C2ec21A7B2](https://mumbai.polygonscan.com/address/0x5Eac339651C18012238a3F89f63F70C2ec21A7B2#code)

- `Forwarder.sol`: [0x10A40362A24f11e4C9e1Dd288b00A55B95b2F807](https://mumbai.polygonscan.com/address/0x10A40362A24f11e4C9e1Dd288b00A55B95b2F807#code)

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

To use scripts, update the transaction parameters in the particular script (e.g. `packId` in `scripts/txs/openPack.ts`) and run e.g -

```bash
  yarn run openPack --network {network name}
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

To deploy the entire protocol, run

```bash
  yarn run deploy-protocol --network {network name}
```

To deploy `Pack.sol` and `Market.sol` as individual modules, run e.g.

```bash
  yarn run deploy-pack --network {network name}
```

Finally, update the `README.md` files with the new addresses, which can be found in `utils/addresses.json`.

## Verify contracts on Etherscan / Polygonscan

To verify the entire protocol, run

```bash
  yarn run verify-protocol --network {network name}
```

To verify individual modules like `Pack.sol`, run

```bash
  yarn run verify-pack --network {network name}
```

## Feedback

If you have any feedback, please reach out to us at support@nftlabs.co.

## Authors

- [NFT Labs](https://github.com/nftlabs)

## License

[GPL v3.0](https://choosealicense.com/licenses/gpl-3.0/)
