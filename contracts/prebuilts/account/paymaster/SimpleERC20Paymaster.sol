// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

// ====== External imports ======
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//  ==========  Internal imports    ==========
import { SafeTransferLib } from "../utils/SafeTransferLib.sol";
import { BasePaymaster } from "../utils/BasePaymaster.sol";

/**
 * @title SimpleERC20Paymaster
 * @dev This contract allows UserOps to be sponsored with a fixed amount of ERC20 tokens instead of the native chain currency.
 * It inherits from the BasePaymaster contract and implements specific logic to handle ERC20 payments for transactions.
 */
contract SimpleERC20Paymaster is BasePaymaster {
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The ERC20 token used for payment
    IERC20 public token;

    /// @dev The price per operation in the specified ERC20 tokens (in wei)
    uint256 public tokenPricePerOp;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when a user operation is successfully sponsored, indicating the actual token cost and gas cost.
     */
    event UserOperationSponsored(address indexed user, uint256 actualTokenNeeded, uint256 actualGasCost);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the paymaster contract with the entry point, token, and price per operation.
     * @param _entryPoint The entry point contract address for handling operations.
     * @param _token The ERC20 token address used for payments.
     * @param _tokenPricePerOp The cost per operation in tokens.
     */
    constructor(IEntryPoint _entryPoint, IERC20 _token, uint256 _tokenPricePerOp) BasePaymaster(_entryPoint) {
        token = _token;
        tokenPricePerOp = _tokenPricePerOp;
    }

    /*///////////////////////////////////////////////////////////////
                            Owner Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows the contract owner to update the token price per operation.
     * @param _tokenPricePerOp The new price per operation in tokens.
     */
    function setTokenPricePerOp(uint256 _tokenPricePerOp) external onlyOwner {
        tokenPricePerOp = _tokenPricePerOp;
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract to a specified address, callable only by the contract owner.
     * @param to The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function withdrawToken(address to, uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransfer(address(token), to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Paymaster Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Validates the paymaster user operation before execution, ensuring sufficient payment and proper data format.
     * @param userOp The user operation to validate.
     * @param context Additional context for validation (unused).
     * @param validationData Additional data for validation (unused).
     * @return context A bytes array for the operation context.
     * @return validationResult The result of the validation, 0 if successful.
     */
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256
    ) internal override returns (bytes memory context, uint256 validationResult) {
        unchecked {
            uint256 cachedTokenPrice = tokenPricePerOp;
            require(cachedTokenPrice != 0, "SPM: price not set");
            uint256 length = userOp.paymasterAndData.length - 20;
            require(
                length & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdf == 0,
                "SPM: invalid data length"
            );
            if (length == 32) {
                require(
                    cachedTokenPrice <= uint256(bytes32(userOp.paymasterAndData[20:52])),
                    "SPM: token amount too high"
                );
            }
            SafeTransferLib.safeTransferFrom(address(token), userOp.sender, address(this), cachedTokenPrice);
            return (abi.encodePacked(cachedTokenPrice, userOp.sender), 0);
        }
    }

    /// @notice Performs post-operation tasks, such as updating the token price and refunding excess tokens.
    /// @dev This function is called after a user operation has been executed or reverted.
    /// @param mode The post-operation mode (either successful or reverted).
    /// @param context The context containing the token amount and user sender address.
    /// @param actualGasCost The actual gas cost of the transaction.
    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        if (mode == PostOpMode.postOpReverted) {
            return; // If operation reverted, do nothing to avoid affecting bundle reputation
        }
        unchecked {
            uint256 actualTokenNeeded = tokenPricePerOp;
            // Refund excess tokens if more were provided than needed
            if (uint256(bytes32(context[0:32])) > actualTokenNeeded) {
                SafeTransferLib.safeTransfer(
                    address(token),
                    address(bytes20(context[32:52])),
                    uint256(bytes32(context[0:32])) - actualTokenNeeded
                );
            } // If the token amount is not greater than the actual amount needed, no refund occurs

            // Emit an event indicating the user operation was sponsored
            emit UserOperationSponsored(address(bytes20(context[32:52])), actualTokenNeeded, actualGasCost);
        }
    }
}
