// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/thirdweb-wallet/Wallet.sol";
import "contracts/thirdweb-wallet/WalletEntrypoint.sol";

import "../utils/BaseTest.sol";

/**
 *  Basic actions [WALLET]:
 *      - Deploy smart contracts
 *      - Make transactions on contracts
 *      - Sign messages
 *      - Own assets
 *
 *  Basic actions [WALLET_ENTRYPOINT]:
 *      - Create accounts.
 *      - Change signer of account.
 *      - Relay transaction to contract wallet.
 *
 *
 *  ARCHITECTURE: https://whimsical.com/smart-contract-wallet-71eMdPs2y2GnG21Aaq8qXS
 */

// TODO: All signature verification must account for both contract and EOA signers.

contract ThirdwebWalletTest is BaseTest {
    WalletEntrypoint private admin;
    Wallet private wallet;

    address private signer1;
    address private signer2;

    function setUp() public {
        // Deploy Architecture:Admin i.e. the entrypoint for a client.
        admin = new WalletEntrypoint();

        signer1 = getActor(100);
        signer2 = getActor(200);
    }

    /**
     *    REQUIREMENTS FOR TXS TO WALLET_ENTRYPOINT.
     *
     *  - Signature from Architecture:BurnerWallet (BW).
     *  - Payload signed by (BW) must contain a validity start and end timestamp.
     *  - Payload signed by (BW) must contain all argument values passed to the function other than the signature.
     */

    /**
     *    REQUIREMENTS FOR TXS FROM WALLET_ENTRYPOINT -> WALLET.
     *
     *  - Signature from Architecture:BurnerWallet (BW).
     *  - Signing (BW) must an approved signer of WALLET.
     *  - Payload signed by (BW) must contain a validity start and end timestamp.
     *  - Payload signed by (BW) must contain all argument values passed to the function other than the signature.
     */

    /**
     *    INVARIABLES FOR WALLET_ENTRYPOINT
     *
     *  - One and the same account associated with a signer, credentials and a (signer, credentials) pair.
     */

    /**
     *    INVARIABLES FOR WALLET
     *
     *  - One and only one WALLET_ENTRYPOINT approved to call into WALLET.
     *  - One and only one signer approved to control WALLET.
     */

    /*///////////////////////////////////////////////////////////////
                Test action: Creating an account.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Creates an account for a (signer, credentials) pair.
     *
     *  Info passed by client:
     *      - signer address
     *      - credentials
     *      - signature of intent from signer
     *      - validity start and end timestamps
     */
    function test_state_createAccount() external {}

    /// @dev Creates an account for a (signer, credentials) pair with a pre-determined address.
    function test_state_createAccount_deterministicAddress() external {}

    /// @dev Creates an account for a (signer, credentials) pair with an initial native token balance.
    function test_balances_createAccount_withInitialBalance() external {}

    /// @dev On creation of an account, event `AccountCreated` is emitted with: account, signer-of-account and creator (i.e. caller) address.
    function test_events_createAccount_AccountCreated() external {}

    /// @dev Cannot create an account with empty credentials (bytes32(0)).
    function test_revert_createAccount_emptyCredentials() external {}

    /// @dev Must sent the exact native token value with transaction as the account's intended initial balance on creation.
    function test_revert_createAccount_incorrectValueSentForInitialBalance() external {}

    /// @dev Must not repeat deployment salt.
    function test_revert_createAccount_repeatingDeploymentSalt() external {}

    /// @dev Signature of intent must be from the target signer for whom the account is created.
    function test_revert_createAccount_signatureNotFromTargetSigner() external {}

    /// @dev The (signer, credentials) pair must not already have an associated account.
    function test_revert_createAccount_signerCredentialPairAlreadyHasAccount() external {}

    /// @dev The request to create account must not be processed at/after validity end timestamp.
    function test_revert_createAccount_requestedAfterValidityEnd() external {}

    /// @dev The request to create account must not be processed before validity start timestamp.
    function test_revert_createAccount_requestedBeforeValidityStart() external {}

    /*///////////////////////////////////////////////////////////////
                Test action: Changing signer for an account.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Changes the signer approved to control WALLET. WALLET_ENTRYPOINT tracks this change.
     *
     *  Info passed by client:
     *      - new signer for account
     *      - new credentials for account
     *      - signature of intent by incumbent signer.
     *      - validity start and end timestamps
     */
    function test_state_changeSignerForAccount() external {}

    function test_revert_changeSignerForAccount_newSignerAlreadyHasAccount() external {}

    function test_revert_changeSignerForAccount_signatureNotFromIncumbentSigner() external {}

    function test_revert_changeSignerForAccount_changingForNonExistentAccount() external {}

    function test_revert_changeSignerForAccount_emptyCredentials() external {}

    function test_revert_changeSignerForAccount_requestBeforeValidityStart() external {}

    function test_revert_changeSignerForAccount_requestAfterValidityEnd() external {}

    /*///////////////////////////////////////////////////////////////
                Test action: Deploying a smart contract.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev WALLET (account) deploys a smart contract.
     *
     *  Info passed by client:
     *      - create2 parameters: initial balance, salt, contract bytecode.
     *      - signature of intent from sigenr
     *      - validity start and end timestamps
     */
    function test_state_deploy() external {}

    function test_state_deploy_deterministicAddress() external {}

    function test_balances_deploy_withInitialBalance() external {}

    function test_revert_deploy_incorrectValueSentForInitialBalance() external {}

    function test_revert_deploy_repeatingDeploymentSaltForSameContract() external {}

    function test_revert_deploy_signatureNotFromIncumbentSigner() external {}

    function test_revert_deploy_requestBeforeValidityStart() external {}

    function test_revert_deploy_requestAfterValidityEnd() external {}

    /*///////////////////////////////////////////////////////////////
                Test action: Calling a smart contract.
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev WALLET (account) performs a contract call.
     *
     *  Info passed by client:
     *      - transaction parameters: target, call data, gas, value, nonce
     *      - signature of intent from sigenr
     *      - validity start and end timestamps
     */
    function test_state_execute() external {}

    function test_revert_execute_executionRevertedInCalledContract() external {}

    function test_revert_deploy_signatureNotFromIncumbentSigner() external {}

    function test_revert_deploy_requestBeforeValidityStart() external {}

    function test_revert_deploy_requestAfterValidityEnd() external {}

    /*///////////////////////////////////////////////////////////////
                Test action: Storing and transferring tokens.
    //////////////////////////////////////////////////////////////*/

    function test_balances_receiveToken_nativeToken() external {}

    function test_balances_transferToken_nativeToken() external {}

    function test_balances_receiveToken_ERC20() external {}

    function test_balances_transferToken_ERC20() external {}

    function test_balances_receiveToken_ERC721() external {}

    function test_balances_transferToken_ERC721() external {}

    function test_balances_receiveToken_ERC1155() external {}

    function test_balances_transferToken_ERC1155() external {}
}
