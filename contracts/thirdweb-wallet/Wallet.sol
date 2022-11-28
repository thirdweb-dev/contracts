// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// ========== Interface ==========
import "./interface/IWallet.sol";

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
contract Wallet is IWallet, EIP712 {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256("Execute(address target,bytes data,uint256 nonce,uint256 txGas,uint256 value)");

    address public controller;
    address public signer;
    uint256 public nonce;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _controller, address _signer) payable EIP712("thirdwebWallet", "1") {
        controller = _controller;
        signer = _signer;
    }

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyController() {
        require(controller == msg.sender, "!Controller");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    function execute(TxParams calldata txParams, bytes memory signature)
        external
        onlyController
        returns (bool success)
    {
        require(txParams.nonce == nonce, "Wallet: invalid nonce.");
        nonce += 1;

        address signer_ = _verifySignature(txParams, signature);
        success = _call(txParams);

        emit TransactionExecuted(
            signer_,
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
        address signer_ = _hash.recover(_signature);

        // Validate signatures
        if (signer == signer_) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }

    function updateSigner(address _newSigner) external onlyController returns (bool success) {
        address prevSigner = signer;
        signer = _newSigner;
        success = true;

        emit SignerUpdated(prevSigner, _newSigner);
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
        returns (address signer_)
    {
        signer_ = _hashTypedDataV4(keccak256(_encodeRequest(_txParams))).recover(_signature);
        require(signer == signer_, "Wallet: invalid signer.");
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
