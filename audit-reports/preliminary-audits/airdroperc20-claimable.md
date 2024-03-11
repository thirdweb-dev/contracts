This document contains details on fixes / response to the preliminary audit reports added to this repository.

## [AirdropERC20Claimable](./airdroperc20-claimable.pdf)

### 01: Governance: TrustedForwarder can execute claims on behalf of other addresses

- The contract doesn't add a trusted-forwarder address by default. The deployer of AirdropERC20Claimable can specify which forwarder they want to use (if any), or leave as address zero.

### 02: Malicious users can steal the entire balance of the contract

- This refers to the possibility of a sybil attack on open/public claims, where multiple wallets can be created to claim the quantity specified by `openClaimLimitPerWallet`. To prevent this scenario or any kind of public claiming, deployer can set `openClaimLimitPerWallet` to zero when setting claim conditions during deployment.
