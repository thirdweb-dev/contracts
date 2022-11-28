// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param _hash      Hash of the data to be signed
     * @param _signature Signature byte array associated with _hash
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
}

interface IWallet is IERC1271 {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    struct DeployParams {
        bytes bytecode;
        bytes32 salt;
        uint256 value;
        uint256 nonce;
    }

    struct TxParams {
        address target;
        bytes data;
        uint256 nonce;
        uint256 value;
        uint256 txGas;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event SignerUpdated(address prevSigner, address newSigner);
    event ContractDeployed(address indexed deployment);
    event TransactionExecuted(
        address indexed signer,
        address indexed target,
        bytes data,
        uint256 indexed nonce,
        uint256 value,
        uint256 txGas
    );

    /*///////////////////////////////////////////////////////////////
                                Functions
    //////////////////////////////////////////////////////////////*/

    function execute(TxParams calldata txParams, bytes memory signature) external returns (bool success);

    function deploy(DeployParams calldata deployParams) external returns (address deployment);

    function updateSigner(address _newSigner) external returns (bool success);
}
