// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract SwapProxy {
    ISwapRouter public immutable swapRouter;
    // ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint24 public constant poolFee = 3000;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of tokenIn for a maximum possible amount of tokenOut
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its tokenIn for this function to succeed.
    /// @param amountIn The exact amount of tokenIn that will be swapped for tokenOut.
    /// @return amountOut The amount of tokenOut received.
    function swapExactInputSingle(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address recipient
    ) external payable returns (uint256 amountOut) {
        // msg.sender must approve this contract

        if (msg.value == 0) {
            // Transfer the specified amount of DAI to this contract.
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );

            // Approve the router to spend DAI.
            TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        }

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        if (msg.value == 0) {
            amountOut = swapRouter.exactInputSingle(params);
        } else {
            amountOut = swapRouter.exactInputSingle{value: msg.value}(params);
        }
    }

    /// @notice swapExactInputMultihop swaps a fixed amount of tokenIn for a maximum possible amount of tokenOut through an intermediary pool.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its tokenIn for this function to succeed.
    /// @param amountIn The amount of tokenIn to be swapped.
    /// @return amountOut The amount of tokenOut received after the swap.
    function swapExactInputMultihop(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address recipient
    ) external returns (uint256 amountOut) {
        // Transfer `amountIn` of tokenIn to this contract.
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        // Approve the router to spend tokenIn.
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        // WETH is always the middle token in testnet since it has the most liquidity on Uniswap
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    tokenIn,
                    poolFee,
                    WETH,
                    poolFee,
                    tokenOut
                ),
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }
}
