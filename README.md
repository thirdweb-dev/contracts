<p align="center">
<br />
<h1 align="center">CryptoPhoenix Smart Wallet Contracts</h1>
<p align="center"><strong>CryptoPhoenix Wallet SDK is a rollup to thirdweb's smart wallet contracts by offering features like: <br />
- Cross-chain payments using Chainlink's CCIP <br />
- Social Account Recovery</strong><br />
<br />

## Inspiration
As we all know, the wallet experience is such a crucial factor in the mass adoption of web3 dapps and services by internet users. For new users to interact with the blockchain, they must: create a wallet, store their private keys, purchase & transfer funds, pay gas fees, and sign every single action that they take on a dApp. With such an intimidating user experience for newcomers, something must change. CryptoPhoenix Wallet SDK is here to bring just that change!

## How we built it
The wallet SDK is a rollup to thirdweb's smart wallet (ERC-4337) contracts. We've added the following contracts to extend it's functionality:
<li> AccountGuardian.sol: Used to assign guardians for smart wallet accounts. </li>
<li> Guardian.sol: Powers the guardian interactions, like attending to account lock & recovery requests. </li>
<li> AccountLock.sol: Adds features like creating and evaluating account lock requests and locking the account assets, if consensus is achieved. </li>
<li> AccountRecovery.sol: Offers the ability to back up account's private key shards, create and evaluate account recovery requests and help with account recovery overall. </li>
<li> CrossChainTokenTransfer.sol: Provides creation of Chainlink's CCIP transfer request, signature verification, and finally implementation according to the ERC-4337 standards. </li>

## Documentation 

[CryptoPhoenix Smart Wallet Contract Docs](https://chukwunonsos-personal-organizati.gitbook.io/cryptophoenix/)

## Authors

- [Shiven](https://github.com/alfheimrShiven)
- [William](https://github.com/techyNonso)

## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt)
