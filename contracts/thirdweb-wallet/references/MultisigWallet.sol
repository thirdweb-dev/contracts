// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../extension/PermissionsEnumerable.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 *  Basic actions:
 *      - Deploy smart contracts
 *      - Make transactions on contracts
 *      - Sign messages
 *      - Own assets
 */

contract MultisigWallet is PermissionsEnumerable, EIP712 {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256("Execute(address target,bytes data,uint256 nonce,uint256 txGas,uint256 value)");

    uint256 public nonce;
    uint256 public threshold;

    mapping(uint256 => mapping(bytes32 => EnumerableSet.AddressSet)) private signersForTx;

    constructor(address _controller, address[] memory _signers) EIP712("thirdwebWallet", "1") {
        _setupRole(CONTROLLER_ROLE, address(this));
        _setupRole(CONTROLLER_ROLE, _controller);
        _setRoleAdmin(CONTROLLER_ROLE, CONTROLLER_ROLE);

        uint256 len = _signers.length;
        for (uint256 i = 0; i < len; i += 1) {
            _setupRole(SIGNER_ROLE, _signers[i]);
        }
    }

    modifier onlyController() {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "!Controller");
        _;
    }

    struct TxParams {
        address target;
        bytes data;
        uint256 nonce;
        uint256 value;
        uint256 txGas;
    }

    function execute(TxParams calldata txParams, bytes[] memory signatures) external onlyController {
        require(txParams.nonce == nonce, "Wallet: invalid nonce.");

        _verifySignatures(txParams, signatures);
        _call(txParams);
    }

    function _verifySignatures(TxParams calldata _txParams, bytes[] memory _signatures) internal {
        bytes32 messageHash = _hashTypedDataV4(keccak256(_encodeRequest(_txParams)));

        uint256 voteCount = signersForTx[_txParams.nonce][messageHash].length();
        uint256 voteCountFixed = voteCount;
        for (uint256 i = 0; i < voteCountFixed; i += 1) {
            address includedSigner = signersForTx[_txParams.nonce][messageHash].at(i);
            if (!hasRole(SIGNER_ROLE, includedSigner)) {
                voteCount -= 1;
            }
        }

        uint256 sigsLen = _signatures.length;
        for (uint256 i = 0; i < sigsLen; i += 1) {
            address signer = messageHash.recover(_signatures[i]);

            require(hasRole(SIGNER_ROLE, signer), "Wallet: invalid signer.");

            bool added = signersForTx[_txParams.nonce][messageHash].add(signer);
            require(added, "Wallet: redundant signer.");
        }
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(TxParams calldata _txParams) internal pure returns (bytes memory) {
        return
            abi.encode(
                EXECUTE_TYPEHASH,
                _txParams.target,
                keccak256(bytes(_txParams.data)),
                _txParams.nonce,
                _txParams.value,
                _txParams.txGas
            );
    }

    function _call(TxParams memory txParams) internal {
        (bool success, bytes memory result) = txParams.target.call{ value: txParams.value, gas: txParams.txGas }(
            txParams.data
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    event ContractDeployed(address indexed deployment);

    function deploy(
        bytes calldata bytecode,
        bytes32 salt,
        uint256 value
    ) external onlyController returns (address deployment) {
        deployment = Create2.deploy(value, salt, bytecode);
        emit ContractDeployed(deployment);
    }
}
