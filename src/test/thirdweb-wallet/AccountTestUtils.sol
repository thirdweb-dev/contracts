// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Account, IAccount } from "contracts/thirdweb-wallet/Account.sol";
import { AccountAdmin, IAccountAdmin } from "contracts/thirdweb-wallet/AccountAdmin.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract AccountAdminData {
    /// @notice Emitted when an account is created.
    event AccountCreated(
        address indexed account,
        address indexed signerOfAccount,
        address indexed creator,
        bytes32 credentials
    );

    /// @notice Emitted on a call to an account.
    event CallResult(bool success, bytes result);

    /// @notice Emitted when a signer is added to an account.
    event SignerAdded(address signer, address account, bytes32 pairHash);

    /// @notice Emitted when a signer is removed from an account.
    event SignerRemoved(address signer, address account, bytes32 pairHash);
}

contract AccountData {
    /// @notice Emitted when a wallet performs a call.
    event TransactionExecuted(
        address indexed signer,
        address indexed target,
        bytes data,
        uint256 indexed nonce,
        uint256 value,
        uint256 gas
    );

    /// @notice Emitted when the wallet deploys a smart contract.
    event ContractDeployed(address indexed deployment);

    /// @notice Emitted when the signer is added to the account.
    event SignerAdded(address signer);

    /// @notice Emitted when the signer is removed from the account.
    event SignerRemoved(address signer);
}

contract AccountUtil is BaseTest {
    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256(
            "TransactionParams(address signer,address target,bytes data,uint256 nonce,uint256 value,uint256 gas,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 private constant DEPLOY_TYPEHASH =
        keccak256(
            "DeployParams(address signer,bytes bytecode,bytes32 salt,uint256 value,uint256 nonce,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 private constant SIGNER_UPDATE_TYPEHASH =
        keccak256(
            "SignerUpdateParams(address signer,bytes32 credentials,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 internal nameHashWallet = keccak256(bytes("thirdwebWallet"));
    bytes32 internal versionHashWallet = keccak256(bytes("1"));
    bytes32 internal typehashEip712Wallet =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function signExecute(
        Account.TransactionParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                EXECUTE_TYPEHASH,
                _params.target,
                keccak256(bytes(_params.data)),
                _params.nonce,
                _params.value,
                _params.gas,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712Wallet, nameHashWallet, versionHashWallet, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function signDeploy(
        Account.DeployParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                DEPLOY_TYPEHASH,
                keccak256(bytes(_params.bytecode)),
                _params.salt,
                _params.value,
                _params.nonce,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712Wallet, nameHashWallet, versionHashWallet, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function signSignerUpdate(
        Account.SignerUpdateParams memory _params,
        uint256 _privateKey,
        address _targetContract
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                SIGNER_UPDATE_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712Wallet, nameHashWallet, versionHashWallet, block.chainid, address(_targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }
}

contract AccountAdminUtil is BaseTest {
    bytes32 private constant CREATE_TYPEHASH =
        keccak256(
            "CreateAccountParams(address signer,bytes32 credentials,bytes32 deploymentSalt,uint256 initialAccountBalance,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );
    bytes32 private constant RELAY_TYPEHASH =
        keccak256(
            "RelayRequestParam(address signer,bytes32 credentials,uint256 value,uint256 gas,bytes data,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 internal nameHash = keccak256(bytes("thirdwebWallet_Admin"));
    bytes32 internal versionHash = keccak256(bytes("1"));
    bytes32 internal typehashEip712 =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function signCreateAccount(
        IAccountAdmin.CreateAccountParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                CREATE_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.deploymentSalt,
                _params.initialAccountBalance,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function signRelayRequest(
        AccountAdmin.RelayRequestParams memory _params,
        uint256 _privateKey,
        address targetContract
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                RELAY_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.value,
                _params.gas,
                keccak256(_params.data),
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(targetContract))
        );
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }
}

contract DummyContract {
    address public deployer;

    constructor() {
        deployer = msg.sender;
    }

    receive() external payable {}

    function revertTx() external pure {
        revert("Execution reverted.");
    }

    function withdraw() external returns (bool success) {
        // solhint-disable-next-line
        require(msg.sender == deployer);
        // solhint-disable-next-line
        (success, ) = (msg.sender).call{ value: address(this).balance }("");
    }
}
