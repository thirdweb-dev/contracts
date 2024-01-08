<p align="center">
<h1 align="center">CryptoPhoenix Smart Wallet Contracts</h1>
<p>CryptoPhoenix Wallet SDK is a rollup to thirdweb's smart wallet contracts and offers: <br />
<ol>
<li>Smart Accounts</li>
<li>Social Account Locking</li>
<li>Social Account Recovery</li>
<li>Guardian Management</li>
</ol>

## Problem Statement
As we all know, a wallet is a gateway to web3 but the wallet experience is unfortunately broken! For a user to interact with a blockchain, they not only have to **create a wallet but also secure their private keys and seed phrase, purchase native tokes to pay for gas, and sign every single action** that they take on a dApp. 

Such an intimidating user experience for newcomers is a big obstacle in the mass adoption of web3 and CryptoPhoenix Wallet SDK is here to change this through its **Account abstraction technology.**

## Smart wallets and its features
Smart wallets are wallets that are controlled by a smart contract and have the following key benefits-
<ol>
<li>
<h4>Abstracted user experience: </h4>
Eliminates the need to manage private keys or seed phrase, making it easier and safer for users to experience Dapps.
</li>
<li>
<h4>Enable gasless transactions:</h4>
Dapps providing smart account can sponser gas on behalf of their users therefore reducing investment to entry and drastically improving user experience as users now don't have to approve each transaction they make with the Dapp.
</li>
<li> 
<h4>Enhanced security through account locking, social recovery and multisig: </h4>
In case the user lose access to their wallet, they can immediately lock their account assets, holding all withdrawal transactions, and can even recover access to their accounts through concensus of their account guardians (trusted people who the user allots to help recover their account in case required). <br />
Smart accounts can also provide multisig capabilities, requiring multiple signatures on a transaction, before it's executed, thus enchancing security.

<li><h4>Automation of transactions</h4>
Enables self executing transactions when certain defined conditions are met like approving a predefined number of tokens to an entity based on fixed time intervals, stop loss and take profit orders, recurring subscriptions, etc.
</li>
</ol>
 
## Architecture

<img src="./images/architecture.png" width="600" alt="cryptophoenix_architecture">
<br/>
<br />

[![YouTube](https://img.shields.io/badge/YouTube-Video-red?style=for-the-badge&logo=youtube)](https://youtu.be/0zq2YdOYFUo?si=Ng6favRkGL9faG_Y)


## Contracts
The wallet SDK is a rollup to thirdweb's smart wallet (ERC-4337) contracts. We've added the following contracts to extend it's functionality:
<li> <b>Account.sol:</b>This is the smart contract that powers the smart wallet by offering features like executing single or batched transactions, locking account assets and updating the owner of the smart account incase of an account recovery is made.</li>
<li> <b>AccountGuardian.sol:</b> Used by the user to assign guardians for smart wallet accounts. </li>
<li> <b>Guardian.sol:</b> Powers the guardian interactions, like attending to account lock & recovery requests for the account they are guarding. </li>
<li> <b>AccountLock.sol:</b> Adds features like creating account lock requests and evaluating concensus on them followed by locking/unlocking the account assets.</li>
<li> <b>AccountRecovery.sol:</b> One of the most important contracts adding features like creating account recovery requests and evaluating concensus on them. Once the concensus is achieved, a new embedded wallet is created and made the owner of the smart contract holding all user assets, thus recovering the account.</li>


## Documentation 

[**CryptoPhoenix Smart Wallet Contract Docs**](https://0xshiven.gitbook.io/cryptophoenix/)

## Author: 
### Shivendra Singh
[![GitHub](https://img.shields.io/badge/GitHub-Profile-black?logo=github)](https://github.com/alfheimrShiven)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-blue?logo=linkedin)](https://www.linkedin.com/in/shivends)
[![Twitter](https://img.shields.io/badge/Twitter-Profile-blue?logo=twitter)](https://twitter.com/0xShiven)
[![Substack](https://img.shields.io/badge/Substack-Newsletter-orange?logo=substack)](https://0xshiven.substack.com/)


## License

[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt)
