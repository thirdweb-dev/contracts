// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./interface/IVault.sol";

import "../../../lib/CurrencyTransferLib.sol";
import "../../../eip/interface/IERC20.sol";

import "../../../extension/PermissionsEnumerable.sol";
import "../../../extension/Initializable.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract Vault is Initializable, PermissionsEnumerable, IVault {
    /// @dev Address of the executor for this vault.
    address public executor;

    /// @dev Address of the Checkout entrypoint.
    address public checkout;

    mapping(address => bool) public isApprovedRouter;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin) external initializer {
        checkout = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    // =================================================
    // =============== Withdraw ========================
    // =================================================

    function withdraw(address _token, uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);

        emit TokensWithdrawn(_token, _amount);
    }

    // =================================================
    // =============== Executor functions ==============
    // =================================================

    function transferTokensToExecutor(address _token, uint256 _amount) external {
        require(_canTransferTokens(), "Not authorized");

        uint256 balance = _token == CurrencyTransferLib.NATIVE_TOKEN
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));

        require(balance >= _amount, "Not enough balance");

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);

        emit TokensTransferredToExecutor(msg.sender, _token, _amount);
    }

    function swapAndTransferTokensToExecutor(address _token, uint256 _amount, SwapOp memory _swapOp) external {
        require(_canTransferTokens(), "Not authorized");
        require(isApprovedRouter[_swapOp.router], "Invalid router address");

        _swap(_swapOp);

        uint256 balance = _token == CurrencyTransferLib.NATIVE_TOKEN
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));

        require(balance >= _amount, "Not enough balance");

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);

        emit TokensTransferredToExecutor(msg.sender, _token, _amount);
    }

    // =================================================
    // =============== Swap functionality ==============
    // =================================================

    function swap(SwapOp memory _swapOp) external {
        require(_canSwap(), "Not authorized");

        _swap(_swapOp);
    }

    function _swap(SwapOp memory _swapOp) internal {
        address _tokenIn = _swapOp.tokenIn;
        address _router = _swapOp.router;

        // get quote for amountIn
        (, bytes memory quoteData) = _router.staticcall(_swapOp.quoteCalldata);
        uint256 amountIn;
        uint256 offset = _swapOp.amountInOffset;

        assembly {
            amountIn := mload(add(add(quoteData, 32), offset))
        }

        // perform swap
        bool success;
        if (_tokenIn == CurrencyTransferLib.NATIVE_TOKEN) {
            (success, ) = _router.call{ value: amountIn }(_swapOp.swapCalldata);
        } else {
            IERC20(_tokenIn).approve(_swapOp.router, amountIn);
            (success, ) = _router.call(_swapOp.swapCalldata);
        }

        require(success, "Swap failed");
    }

    // =================================================
    // =============== Setter functions ================
    // =================================================

    function setExecutor(address _executor) external {
        require(_canSetExecutor(), "Not authorized");
        if (_executor == executor) {
            revert("Executor already set");
        }

        executor = _executor;
    }

    function approveSwapRouter(address _swapRouter, bool _toApprove) external {
        require(_canSetSwap(), "Not authorized");
        require(_swapRouter != address(0), "Zero address");

        isApprovedRouter[_swapRouter] = _toApprove;
    }

    // =================================================
    // =============== Role checks =====================
    // =================================================

    function canAuthorizeVaultToExecutor(address _expectedAdmin) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _expectedAdmin);
    }

    function _canSetExecutor() internal view returns (bool) {
        return msg.sender == checkout;
    }

    function _canTransferTokens() internal view returns (bool) {
        return msg.sender == executor;
    }

    function _canSwap() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _canSetSwap() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
