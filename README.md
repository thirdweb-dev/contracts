<p align="center">
<h1 align="center">CryptoPhoenix Smart Wallet Contracts</h1>
<p>CryptoPhoenix Wallet SDK is a rollup to thirdweb's smart wallet contracts and offers: <br />
<ol>
<li>Social Account Locking</li>
<li>Social Account Recovery</li>
<li>Guardian Management</li>
</ol>

## Problem Statement
As we all know, a wallet is a gateway to web3 but the wallet experience is unfortunately broken as for a user to interact with a blockchain, they not only have to create a wallet but also secure their private keys and seed phrase, purchase native tokes to pay for gas, and sign every single action that they take on a dApp. 

Such an intimidating user experience for newcomers is a big hindrance in the mass adoption of web3 and CryptoPhoenix Wallet SDK is here to change this through its **Account abstraction technology.**

## Architecture

<img src="./images/architecture.png" width="400" alt="puppy-raffle">
<br/>
<br />

[**Architecture walkthrough**](https://www.youtube.com/embed/0zq2YdOYFUo)



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
