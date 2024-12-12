// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable not-rely-on-time */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

abstract contract UniswapHelper {
    event UniswapReverted(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin);

    uint256 private constant PRICE_DENOMINATOR = 1e26;

    struct UniswapHelperConfig {
        /// @notice Minimum native asset amount to receive from a single swap
        uint256 minSwapAmount;
        uint24 uniswapPoolFee;
        uint8 slippage;
        bool wethIsNativeAsset;
    }

    /// @notice The Uniswap V3 SwapRouter contract
    IV3SwapRouter public immutable uniswap;

    /// @notice The ERC20 token used for transaction fee payments
    IERC20Metadata public immutable token;

    /// @notice The ERC-20 token that wraps the native asset for current chain
    IERC20 public immutable wrappedNative;

    UniswapHelperConfig public uniswapHelperConfig;

    constructor(
        IERC20Metadata _token,
        IERC20 _wrappedNative,
        IV3SwapRouter _uniswap,
        UniswapHelperConfig memory _uniswapHelperConfig
    ) {
        _token.approve(address(_uniswap), type(uint256).max);
        token = _token;
        wrappedNative = _wrappedNative;
        uniswap = _uniswap;
        _setUniswapHelperConfiguration(_uniswapHelperConfig);
    }

    function _setUniswapHelperConfiguration(UniswapHelperConfig memory _uniswapHelperConfig) internal {
        uniswapHelperConfig = _uniswapHelperConfig;
    }

    function _maybeSwapTokenToWeth(IERC20Metadata tokenIn, uint256 quote) internal returns (uint256) {
        uint256 tokenBalance = tokenIn.balanceOf(address(this));
        uint256 tokenDecimals = tokenIn.decimals();

        uint256 amountOutMin = addSlippage(
            tokenToWei(tokenBalance, tokenDecimals, quote),
            uniswapHelperConfig.slippage
        );

        if (amountOutMin < uniswapHelperConfig.minSwapAmount) {
            return 0;
        }
        // note: calling 'swapToToken' but destination token is Wrapped Ether
        return
            swapToToken(
                address(tokenIn),
                address(wrappedNative),
                tokenBalance,
                amountOutMin,
                uniswapHelperConfig.uniswapPoolFee
            );
    }

    function addSlippage(uint256 amount, uint8 slippage) private pure returns (uint256) {
        return (amount * (1000 - slippage)) / 1000;
    }

    function tokenToWei(uint256 amount, uint256 decimals, uint256 price) public pure returns (uint256) {
        return (amount * price * (10 ** (18 - decimals))) / PRICE_DENOMINATOR;
    }

    function weiToToken(uint256 amount, uint256 decimals, uint256 price) public pure returns (uint256) {
        return (amount * PRICE_DENOMINATOR) / (price * (10 ** (18 - decimals)));
    }

    function unwrapWeth(uint256 amount) internal {
        if (uniswapHelperConfig.wethIsNativeAsset) {
            return;
        }
        IPeripheryPayments(address(uniswap)).unwrapWETH9(amount, address(this));
    }

    // swap ERC-20 tokens at market price
    function swapToToken(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams(
            tokenIn, //tokenIn
            tokenOut, //tokenOut
            fee,
            address(uniswap),
            amountIn,
            amountOutMin,
            0
        );
        try uniswap.exactInputSingle(params) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {
            emit UniswapReverted(tokenIn, tokenOut, amountIn, amountOutMin);
            amountOut = 0;
        }
    }
}
