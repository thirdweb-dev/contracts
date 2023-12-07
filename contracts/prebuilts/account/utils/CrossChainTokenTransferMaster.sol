// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { AccountExtension } from "contracts/prebuilts/account/utils/AccountExtension.sol";

/**
 * @title CrossChainTokenTransferMaster
 * @dev This is a smart contract that controls the activities of the cross chain token transfer contract
 */

contract CrossChainTokenTransferMaster is AccountExtension, Ownable {
    // Target contracts
    EntryPoint private entrypoint;
    //contract states
    address payable private beneficiary = payable(address(0x45654));
    mapping(address => UserOperation) private userOPS;
    event HashGenerated(address indexed owner, bytes32 hash);
    event RoleChanged(SignerPermissionRequest req);
    uint192 private nonceValue = 0;

    uint public callGasLimit = 500_000;
    uint public verificationGasLimit = 500_000;
    uint public preVerificationGas = 500_000;
    uint public maxFeePerGas = 0;
    uint public maxPriorityFeePerGas = 0;

    function setCallGasLimit(uint _value) external onlyOwner {
        callGasLimit = _value;
    }

    function setVerificationGasLimit(uint _value) external onlyOwner {
        verificationGasLimit = _value;
    }

    function setPreVerificationGas(uint _value) external onlyOwner {
        preVerificationGas = _value;
    }

    function setMaxFeePerGas(uint _value) external onlyOwner {
        maxFeePerGas = _value;
    }

    function setMaxPriorityPerGas(uint _value) external onlyOwner {
        maxPriorityFeePerGas = _value;
    }

    /**
     * @dev Sets beneficiary of the transaction
     * @param _beneficiary Address of the beneficiary
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = payable(_beneficiary);
    }

    /**
     * @dev Generates userOP objects
     * @param _initCode Guide for entry point
     * @param _callDataForEntrypoint The calls to be performed
     * @param _sender The smart wallet address
     * @return msgHash The userop hash
     */
    function _setupUserOp(
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint,
        address _sender
    ) internal returns (bytes32 msgHash) {
        uint256 nonce = entrypoint.getNonce(_sender, nonceValue);

        // Get user op fields
        UserOperation memory op = UserOperation({
            sender: _sender,
            nonce: nonce,
            initCode: _initCode,
            callData: _callDataForEntrypoint,
            callGasLimit: callGasLimit,
            verificationGasLimit: verificationGasLimit,
            preVerificationGas: preVerificationGas,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });

        //store userOP
        userOPS[_sender] = op;
        // get OP hash
        bytes32 opHash = EntryPoint(entrypoint).getUserOpHash(op);
        //increase nonce
        nonceValue++;
        msgHash = ECDSA.toEthSignedMessageHash(opHash);
    }

    /**
     * @dev Set of the transaction batch
     * @param _initCode Guide for entry point
     * @param _target The target contracts array
     * @param _sender The smart wallet address
     * @param _callData The call to be performed
     * @return msgHash The userop hash
     */
    function _setupUserOpExecuteBatch(
        bytes memory _initCode,
        address[] memory _target,
        uint256[] memory _value,
        bytes[] memory _callData,
        address _sender
    ) internal returns (bytes32) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "executeBatch(address[],uint256[],bytes[])",
            _target,
            _value,
            _callData
        );

        return _setupUserOp(_initCode, callDataForEntrypoint, _sender);
    }

    /**
     * @dev Initiate token transfer with Link payment
     * @param _smartWalletAccount The smart wallet address
     * @param _ccip Address of chain token transfer contract
     * @param _link Address of Link contract
     * @param _token Address of erc20 contract
     * @param _destinationChainSelector The destination chain selector
     * @param _receiver The receiver address
     * @param _tokenAmount The amount of token to be sent
     * @param _linkAmount The estimated link token required for the transaction
     */
    function _initiateTokenTransferWithLink(
        address _smartWalletAccount,
        address _ccip,
        address _link,
        address _token,
        uint64 _destinationChainSelector,
        address _receiver,
        uint _tokenAmount,
        uint _linkAmount
    ) public {
        uint256 count = 3;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        //approve link tokens for chain token transfer contract
        targets[0] = _link;
        values[0] = 0;
        callData[0] = abi.encodeWithSignature("approve(address, uint)", _ccip, _linkAmount);

        //approve erc20 for chain token transfer contract
        targets[1] = _token;
        values[1] = 0;
        callData[1] = abi.encodeWithSignature("approve(address, uint)", _ccip, _tokenAmount);

        //start cross chain transfer
        targets[2] = _ccip;
        values[2] = 0;
        callData[2] = abi.encodeWithSignature(
            "transferTokensPayLINK(uint64 , address , address , address ,uint256 , uint256,   uint256 )",
            _destinationChainSelector,
            _receiver,
            _smartWalletAccount,
            _token,
            _tokenAmount,
            _linkAmount,
            _tokenAmount
        );

        //generate user OP
        bytes32 userOpHash = _setupUserOpExecuteBatch(bytes(""), targets, values, callData, _smartWalletAccount);
        //emit generated userOP
        emit HashGenerated(_smartWalletAccount, userOpHash);
    }

    /**
     * @dev Initiate token transfer with native payment
     * @param _smartWalletAccount The smart wallet address
     * @param _ccip Address of chain token transfer contract
     * @param _token Address of erc20 contract
     * @param _destinationChainSelector The destination chain selector
     * @param _receiver The receiver address
     * @param _tokenAmount The amount of token to be sent
     * @param _estimatedAmount The estimated native token required for the transaction
     */
    function _initiateTokenTransferWithNativeToken(
        address _smartWalletAccount,
        address _ccip,
        address _token,
        uint64 _destinationChainSelector,
        address _receiver,
        uint _tokenAmount,
        uint _estimatedAmount
    ) public {
        uint256 count = 2;
        address[] memory targets = new address[](count);
        uint256[] memory values = new uint256[](count);
        bytes[] memory callData = new bytes[](count);

        //approve token for cross chain token transfer contract
        targets[0] = _token;
        values[0] = 0;
        callData[0] = abi.encodeWithSignature("approve(address, uint)", _ccip, _tokenAmount);

        // start the cross chain transfer
        targets[1] = _ccip;
        values[1] = _estimatedAmount;
        callData[1] = abi.encodeWithSignature(
            "transferTokensPayNative( uint64 ,  address ,  address , address,  uint256 , uint256   )",
            _destinationChainSelector,
            _receiver,
            _smartWalletAccount,
            _token,
            _tokenAmount,
            _tokenAmount
        );

        //set up userOP
        bytes32 userOpHash = _setupUserOpExecuteBatch(bytes(""), targets, values, callData, _smartWalletAccount);
        //emit event for user op generation
        emit HashGenerated(_smartWalletAccount, userOpHash);
    }

    /**
     * @dev Complete transaction after it has been signed
     * @param _messageHash The hash of the userOp
     * @param _signature The signature of the signer
     */
    function proceed(bytes32 _messageHash, bytes memory _signature) external {
        address signer = ECDSA.recover(_messageHash, _signature);
        //verify signature
        bytes32 value = isValidSignature(_messageHash, _signature);
        require(value == MAGICVALUE, "Invalid Signer");
        //get user  op
        UserOperation storage userOP = userOPS[signer];
        //array of userOPs
        UserOperation[] memory ops = new UserOperation[](1);
        userOP.signature = _signature;
        ops[0] = userOP;
        //pass operation to entry point
        EntryPoint(entrypoint).handleOps(ops, beneficiary);
    }
}
