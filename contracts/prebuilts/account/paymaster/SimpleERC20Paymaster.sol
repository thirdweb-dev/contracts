// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeTransferLib } from "../utils/SafeTransferLib.sol";

import "../utils/BasePaymaster.sol";

contract SimpleERC20Paymaster is BasePaymaster {
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public tokenPricePerOp;

    event UserOperationSponsored(address indexed user, uint256 actualTokenNeeded, uint256 actualGasCost);

    constructor(IEntryPoint _entryPoint, IERC20 _token, uint256 _tokenPricePerOp) BasePaymaster(_entryPoint) {
        token = _token;
        tokenPricePerOp = _tokenPricePerOp;
    }

    function setTokenPricePerOp(uint256 _tokenPricePerOp) external onlyOwner {
        tokenPricePerOp = _tokenPricePerOp;
    }

    function withdrawToken(address to, uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransfer(address(token), to, amount);
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256
    ) internal override returns (bytes memory context, uint256 validationResult) {
        unchecked {
            uint256 cachedTokenPrice = tokenPricePerOp;
            require(cachedTokenPrice != 0, "SPM : price not set");
            uint256 length = userOp.paymasterAndData.length - 20;
            // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdf is the mask for the last 6 bits 011111 which mean length should be 100000(32) || 000000(0)
            require(
                length & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdf == 0,
                "SPM : invalid data length"
            );
            // NOTE: we assumed that nativeAsset's decimals is 18
            if (length == 32) {
                require(
                    cachedTokenPrice <= uint256(bytes32(userOp.paymasterAndData[20:52])),
                    "SPM : token amount too high"
                );
            }
            SafeTransferLib.safeTransferFrom(address(token), userOp.sender, address(this), cachedTokenPrice);
            context = abi.encodePacked(cachedTokenPrice, userOp.sender);
            // No return here since validationData == 0 and we have context saved in memory
            validationResult = 0;
        }
    }

    /// @notice Performs post-operation tasks, such as updating the token price and refunding excess tokens.
    /// @dev This function is called after a user operation has been executed or reverted.
    /// @param mode The post-operation mode (either successful or reverted).
    /// @param context The context containing the token amount and user sender address.
    /// @param actualGasCost The actual gas cost of the transaction.
    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        if (mode == PostOpMode.postOpReverted) {
            return; // Do nothing here to not revert the whole bundle and harm reputation
        }
        unchecked {
            uint256 actualTokenNeeded = tokenPricePerOp;
            if (uint256(bytes32(context[0:32])) > actualTokenNeeded) {
                // If the initially provided token amount is greater than the actual amount needed, refund the difference
                SafeTransferLib.safeTransfer(
                    address(token),
                    address(bytes20(context[32:52])),
                    uint256(bytes32(context[0:32])) - actualTokenNeeded
                );
            } // If the token amount is not greater than the actual amount needed, no refund occurs

            emit UserOperationSponsored(address(bytes20(context[32:52])), actualTokenNeeded, actualGasCost);
        }
    }
}
