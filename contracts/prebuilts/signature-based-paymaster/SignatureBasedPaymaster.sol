// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {IPaymaster, ExecutionResult, PAYMASTER_VALIDATION_SUCCESS_MAGIC} from "@zksync/l2/system-contracts/interfaces/IPaymaster.sol";
import {IPaymasterFlow} from "@zksync/l2/system-contracts/interfaces/IPaymasterFlow.sol";
import {TransactionHelper, Transaction} from "@zksync/l2/system-contracts/libraries/TransactionHelper.sol";

import "@zksync/l2/system-contracts/Constants.sol";

/// @notice This smart contract pays the gas fees on behalf of users that provide valid signature from the signer.
/// @dev This contract is controlled by an owner, who can update the signer, cancel a user's nonce and withdraw funds from contract.
contract SignatureBasedPaymaster is IPaymaster, Ownable, EIP712 {
    using ECDSA for bytes32;
    // Note - EIP712 Domain compliance typehash. TYPES should exactly match while signing signature to avoid signature failure.
    bytes32 public constant SIGNATURE_TYPEHASH = keccak256(
    "SignatureBasedPaymaster(address userAddress,uint256 lastTimestamp,uint256 nonces)"
    );
    // All signatures should be validated based on signer
    address public signer;
    // Mapping user => nonce to guard against signature re-play attack.
    mapping(address => uint256) public nonces;

    modifier onlyBootloader() {
        require(
            msg.sender == BOOTLOADER_FORMAL_ADDRESS,
            "Only bootloader can call this method"
        );
        // Continue execution if called from the bootloader.
        _;
    }

/// @param _signer Sets the signer to validate against signatures
/// @dev Changes in EIP712 constructor arguments - "name","version" would update domainSeparator which should be taken into considertion while signing.
    constructor(address _signer) EIP712("SignatureBasedPaymaster","1") {
        require(_signer != address(0), "Signer cannot be address(0)");
        // Owner can be signer too.
        signer = _signer;
    }

    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    )
        external
        payable
        onlyBootloader
        returns (bytes4 magic, bytes memory context)
    {
        // By default we consider the transaction as accepted.
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        require(
            _transaction.paymasterInput.length >= 4,
            "The standard paymaster input must be at least 4 bytes long"
        );

        bytes4 paymasterInputSelector = bytes4(
            _transaction.paymasterInput[0:4]
        );
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            // Note - We first need to decode innerInputs data to bytes.
            (bytes memory innerInputs) = abi.decode(
                _transaction.paymasterInput[4:],
                (bytes)
            );
            // Note - Decode the innerInputs as per encoding. Here, we have encoded lastTimestamp and signature in innerInputs
            (uint lastTimestamp, bytes memory sig) = abi.decode(innerInputs,(uint256,bytes));

            // Verify signature expiry based on timestamp.
            // lastTimestamp is used in signature hash, hence cannot be faked.
            require(block.timestamp <= lastTimestamp, "Paymaster: Signature expired");
            // Get user address from transaction.from
            address userAddress = address(uint160(_transaction.from));
            // Generate hash
            bytes32 hash = keccak256(abi.encode(SIGNATURE_TYPEHASH, userAddress,lastTimestamp, nonces[userAddress]++));
            // EIP712._hashTypedDataV4 hashes with domain separator that includes chain id. Hence prevention to signature replay atttacks.
            bytes32 digest = _hashTypedDataV4(hash);
            // Revert if signer not matched with recovered address. Reverts on address(0) as well.
            require(signer == digest.recover(sig),"Paymaster: Invalid signer");


            // Note, that while the minimal amount of ETH needed is tx.gasPrice * tx.gasLimit,
            // neither paymaster nor account are allowed to access this context variable.
            uint256 requiredETH = _transaction.gasLimit *
                _transaction.maxFeePerGas;

            // The bootloader never returns any data, so it can safely be ignored here.
            (bool success, ) = payable(BOOTLOADER_FORMAL_ADDRESS).call{
                value: requiredETH
            }("");
            require(
                success,
                "Failed to transfer tx fee to the bootloader. Paymaster balance might not be enough."
            );
        } else {
            revert("Unsupported paymaster flow");
        }
    }

    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult _txResult,
        uint256 _maxRefundedGas
    ) external payable override onlyBootloader {
        // Refunds are not supported yet.
    }
    function withdraw(address _to) external onlyOwner {
        // send paymaster funds to the owner
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        require(success, "Failed to withdraw funds from paymaster.");

    }
    receive() external payable {}

    /// @dev Only owner should be able to change signer.
    /// @param _signer New signer address
    function changeSigner(address _signer) onlyOwner public {
        signer = _signer;
    }
    /// @dev Only owner should be able to update user nonce.
    /// @dev There could be a scenario where owner needs to cancel paying gas for a certain user transaction.
    /// @param _userAddress user address to update the nonce.
    function cancelNonce(address _userAddress) onlyOwner public {
        nonces[_userAddress]++;
    }

    function domainSeparator() public view returns(bytes32) {
        return _domainSeparatorV4();
    }
}
