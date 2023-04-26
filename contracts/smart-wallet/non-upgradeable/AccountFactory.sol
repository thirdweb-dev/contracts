// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../../extension/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../lib/TWStringSet.sol";

// Interface
import "./../interfaces/IAccountFactory.sol";

// Smart wallet implementation
import "./Account.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract AccountFactory is IAccountFactory, Multicall {
    using TWStringSet for TWStringSet.Set;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    Account private immutable _accountImplementation;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) {
        _accountImplementation = new Account(_entrypoint);
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new Account with the given admin and accountId used as salt.
    function createAccount(address _admin, string memory _accountId) external returns (address) {
        address impl = address(_accountImplementation);
        bytes32 salt = keccak256(abi.encode(_accountId));
        address account = Clones.predictDeterministicAddress(impl, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = Clones.cloneDeterministic(impl, salt);

        Account(payable(account)).initialize(_admin);

        emit AccountCreated(account, _admin, _accountId);

        return account;
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the implementation of the Account.
    function accountImplementation() external view override returns (address) {
        return address(_accountImplementation);
    }

    /// @notice Returns the address of an Account that would be deployed with the given accountId as salt.
    function getAddress(string memory _accountId) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(_accountId));
        return Clones.predictDeterministicAddress(address(_accountImplementation), salt);
    }
}
