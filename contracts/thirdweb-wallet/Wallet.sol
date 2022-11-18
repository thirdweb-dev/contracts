// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// ========== Extension ==========
import "../extension/PermissionsEnumerable.sol";

// ========== Utils ==========
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 *  Basic actions:
 *      - Deploy smart contracts ✅
 *      - Make transactions on contracts ✅
 *      - Sign messages ✅
 *      - Own assets ✅
 */

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
}

contract Wallet is IWallet, PermissionsEnumerable, EIP712 {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256("Execute(address target,bytes data,uint256 nonce,uint256 txGas,uint256 value)");

    uint256 public nonce;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _controller, address _signer) EIP712("thirdwebWallet", "1") {
        _setupRole(CONTROLLER_ROLE, address(this));
        _setupRole(CONTROLLER_ROLE, _controller);
        _setRoleAdmin(CONTROLLER_ROLE, CONTROLLER_ROLE);

        _setupRole(SIGNER_ROLE, _signer);
    }

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyController() {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "!Controller");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function execute(TxParams calldata txParams, bytes memory signature)
        external
        onlyController
        returns (bool success)
    {
        require(txParams.nonce == nonce, "Wallet: invalid nonce.");
        nonce += 1;

        address signer = _verifySignature(txParams, signature);
        success = _call(txParams);

        emit TransactionExecuted(
            signer,
            txParams.target,
            txParams.data,
            txParams.nonce,
            txParams.value,
            txParams.txGas
        );
    }

    function deploy(DeployParams calldata deployParams) external onlyController returns (address deployment) {
        require(deployParams.nonce == nonce, "Wallet: invalid nonce.");
        nonce += 1;

        deployment = Create2.deploy(deployParams.value, deployParams.salt, deployParams.bytecode);
        emit ContractDeployed(deployment);
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view override returns (bytes4) {
        address signer = _hash.recover(_signature);

        // Validate signatures
        if (hasRole(SIGNER_ROLE, signer)) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    function _verifySignature(TxParams calldata _txParams, bytes memory _signature)
        internal
        view
        returns (address signer)
    {
        signer = _hashTypedDataV4(keccak256(_encodeRequest(_txParams))).recover(_signature);
        require(hasRole(SIGNER_ROLE, signer), "Wallet: invalid signer.");
    }

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

    function _call(TxParams memory txParams) internal returns (bool) {
        (bool success, bytes memory result) = txParams.target.call{ value: txParams.value, gas: txParams.txGas }(
            txParams.data
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return success;
    }
}
