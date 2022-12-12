// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IAccounAdminMulti {
    ////////// Creating accounts //////////

    struct CreateAccountParams {
        address signer;
        bytes32 credentials;
        bytes32 deploymentSalt;
        uint256 initialAccountBalance;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    function createAccount(CreateAccountParams calldata params, bytes calldata signature)
        external
        payable
        returns (address account);

    ////////// Relaying transaction to account //////////

    struct RelayRequestParams {
        address signer;
        bytes32 credentials;
        uint256 value;
        uint256 gas;
        bytes data;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    function execute(RelayRequestParams calldata params, bytes memory signature)
        external
        payable
        returns (bool success, bytes memory result);

    ////////// Changes to signer composition of accounts //////////

    struct SignerUpdateParams {
        address account;
        address actingSigner;
        bytes32 actingSignerCredentials;
        address newSigner;
        bytes32 newCredentials;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    function updateSignerForAccount(SignerUpdateParams calldata params, bytes memory signature) external;
}
