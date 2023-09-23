// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISwapProxy {
    function swapExactInputSingle(uint256 amountIn, address tokenIn, address tokenOut, address recipient) external payable returns (uint256 amountOut);
}