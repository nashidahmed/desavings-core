# DeSavings contracts

This is a hardhat repo for the smart contracts. There is one Factory contract called `SavingsFactory` through which users can create their own automated `Savings` contract. Then there is a `SwapProxy` contract which makes use of Uniswap to swap the tokens. There are two interfaces, namely the `ISwapProxy` contract which allows us to interact with the `SwapProxy` contract, and the `IWETH9.sol` contract from Uniswap, which allows us to withdraw ETH from WETH tokens.
