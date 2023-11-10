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
    /// @dev Mapping from token address to total balance in the vault.
    mapping(address => uint256) public tokenBalance;

    /// @dev Address of the executor for this vault.
    address public executor;

    /// @dev Address of the Checkout entrypoint.
    address public checkout;

    address public immutable swapToken;

    constructor(address _swapToken) {
        swapToken = _swapToken;
        _disableInitializers();
    }

    function initialize(address _defaultAdmin) external initializer {
        checkout = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    // =================================================
    // =============== Deposit and Withdraw ============
    // =================================================

    function deposit(address _token, uint256 _amount) external payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");

        uint256 _actualAmount;

        if (_token == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == _amount, "!Amount");
            _actualAmount = _amount;

            tokenBalance[_token] += _actualAmount;
        } else {
            uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
            CurrencyTransferLib.safeTransferERC20(_token, msg.sender, address(this), _amount);
            _actualAmount = IERC20(_token).balanceOf(address(this)) - balanceBefore;

            tokenBalance[_token] += _actualAmount;
        }

        emit TokensDeposited(_token, _actualAmount);
    }

    function withdraw(address _token, uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");

        uint256 balance = tokenBalance[_token];
        // to prevent locking of direct-transferred tokens
        tokenBalance[_token] = _amount > balance ? 0 : balance - _amount;

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);

        emit TokensWithdrawn(_token, _amount);
    }

    // =================================================
    // =============== Executor functions ==============
    // =================================================

    function transferTokensToExecutor(address _token, uint256 _amount) external {
        require(_canTransferTokens(), "Not authorized");

        uint256 balance = tokenBalance[_token];
        require(balance >= _amount, "Not enough balance");

        tokenBalance[_token] -= _amount;

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);

        emit TokensTransferredToExecutor(msg.sender, _token, _amount);
    }

    function swapAndTransferTokensToExecutor(address _token, uint256 _amount) external {
        require(_canTransferTokens(), "Not authorized");

        _swap();

        uint256 balance = tokenBalance[_token];
        require(balance >= _amount, "Not enough balance");

        tokenBalance[_token] -= _amount;

        CurrencyTransferLib.transferCurrency(_token, address(this), msg.sender, _amount);

        emit TokensTransferredToExecutor(msg.sender, _token, _amount);
    }

    // =================================================
    // =============== Swap functionality ==============
    // =================================================

    function swap() external {
        require(_canSwap(), "Not authorized");

        _swap();
    }

    function _swap() internal {}

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

    // function setSwapToken(address _swapToken) external {
    //     require(_canSetSwapToken(), "Not authorized");

    //     swapToken = _swapToken;
    // }

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

    function _canSetSwapToken() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
