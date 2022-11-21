// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./Wallet.sol";

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 *  Basic actions:
 *      - Create accounts.
 *      - Add signer to account.
 *      - Remove signer from account.
 *      - Relay transaction to contract wallet.
 */

interface IWalletEntrypoint {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    struct TransactionRequest {
        bytes32 signerCredentials;
        uint256 value;
        uint256 gas;
        bytes data;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event AccountCreated(address indexed signer);
    event CallResult(bool success, bytes result);

    /*///////////////////////////////////////////////////////////////
                                Functions
    //////////////////////////////////////////////////////////////*/

    function createAccount(
        bytes32 credentials,
        address signer,
        bytes calldata signature
    ) external returns (address account);

    function execute(TransactionRequest calldata req) external payable returns (bool, bytes memory);
}

contract WalletEntrypoint is IWalletEntrypoint {
    bytes32 private constant CREDENTIALS_TYPEHASH = keccak256("Create(bytes32 credentials)");

    /// @dev Mapping from signer => credentials.
    mapping(address => bytes32) private credentialsOf;

    /// @dev Mapping from hash(signer, credentials) => account.
    mapping(bytes32 => address) private accountOf;

    function createAccount(
        bytes32 credentials,
        address signer,
        bytes calldata signature
    ) external returns (address account) {
        // TODO: Verify signer / signature.
        account = address(new Wallet(address(this), signer));

        credentialsOf[signer] = credentials;
        accountOf[keccak256(abi.encode(signer, credentials))] = account;
    }

    function execute(TransactionRequest calldata req) public payable returns (bool, bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = accountOf[req.signerCredentials].call{ gas: req.gas, value: req.value }(
            req.data
        );

        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert("Transaction reverted silently");
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        // Check gas: https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.gas / 63);

        emit CallResult(success, result);

        return (success, result);
    }
}
