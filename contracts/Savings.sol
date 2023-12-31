// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISwapProxy.sol";
import "./interfaces/IWETH9.sol";

contract Savings is AutomationCompatible {
    event ReceivedFunds(
        address indexed savings,
        address tokenIn,
        uint256 amountIn,
        OutgoingToken[] outgoingTokens
    );

    // Goerli token addresses for testing [["0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", 20], ["0x07865c6E87B9F70255377e024ace6630C1Eaa37F", 80]]
    // address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    // address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    // address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    struct TokenDistribution {
        address token;
        uint8 distribution;
    }

    struct OutgoingToken {
        address token;
        uint256 amount;
    }

    address public immutable owner;
    ISwapProxy swapProxy;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    address[] public whitelistTokens;
    TokenDistribution[] tokenDistribution;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        ISwapProxy _swapProxy,
        address _owner,
        address[] memory _whitelistTokens,
        TokenDistribution[] memory _tokenDistribution
    ) {
        swapProxy = _swapProxy;
        owner = _owner;
        whitelistTokens = _whitelistTokens;

        for (uint256 x = 0; x < _tokenDistribution.length; x++) {
            tokenDistribution.push(
                TokenDistribution(
                    _tokenDistribution[x].token,
                    _tokenDistribution[x].distribution
                )
            );
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (address(this).balance > 0) {
            return (true, "");
        } else {
            for (uint x = 0; x < whitelistTokens.length; x++) {
                if (IERC20(whitelistTokens[x]).balanceOf(address(this)) > 0) {
                    performData = abi.encode(whitelistTokens[x]);
                    return (true, performData);
                }
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        address whitelistToken;
        OutgoingToken[] memory outgoingTokens = new OutgoingToken[](
            tokenDistribution.length
        );

        if (performData.length != 0) {
            (whitelistToken) = abi.decode(performData, (address));
        }

        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (address(this).balance > 0) {
            uint256 balance = address(this).balance;

            for (uint256 x = 0; x < tokenDistribution.length; x++) {
                uint256 amount = (balance * tokenDistribution[x].distribution) /
                    100;
                if (
                    tokenDistribution[x].token == address(0) ||
                    tokenDistribution[x].token == WETH
                ) {
                    (bool sent, ) = owner.call{value: amount}("");
                    require(sent, "Failed to send ether");
                    outgoingTokens[x] = OutgoingToken(
                        tokenDistribution[x].token,
                        amount
                    );
                } else {
                    uint256 amountOut = swapProxy.swapExactInputSingle{
                        value: amount
                    }(amount, WETH, tokenDistribution[x].token, owner);
                    outgoingTokens[x] = OutgoingToken(
                        tokenDistribution[x].token,
                        amountOut
                    );
                }
            }

            emit ReceivedFunds(
                address(this),
                address(0),
                balance,
                outgoingTokens
            );
        } else if (IERC20(whitelistToken).balanceOf(address(this)) > 0) {
            uint256 balance = IERC20(whitelistToken).balanceOf(address(this));

            for (uint x = 0; x < tokenDistribution.length; x++) {
                uint256 amount = (balance * tokenDistribution[x].distribution) /
                    100;
                if (tokenDistribution[x].token == whitelistToken) {
                    IERC20(whitelistToken).transfer(owner, amount);
                    outgoingTokens[x] = OutgoingToken(whitelistToken, amount);
                } else {
                    if (
                        tokenDistribution[x].token == address(0) ||
                        tokenDistribution[x].token == WETH
                    ) {
                        IERC20(whitelistToken).approve(
                            address(swapProxy),
                            amount
                        );
                        uint256 amountOut = swapProxy.swapExactInputSingle(
                            amount,
                            whitelistToken,
                            tokenDistribution[x].token,
                            address(this)
                        );
                        IWETH9(WETH).withdraw(amountOut);
                        (bool sent, ) = owner.call{value: amountOut}("");
                        require(sent, "Failed to send ether");
                        outgoingTokens[x] = OutgoingToken(
                            tokenDistribution[x].token,
                            amountOut
                        );
                    } else {
                        IERC20(whitelistToken).approve(
                            address(swapProxy),
                            amount
                        );
                        uint256 amountOut = swapProxy.swapExactInputMultihop(
                            amount,
                            whitelistToken,
                            tokenDistribution[x].token,
                            owner
                        );
                        outgoingTokens[x] = OutgoingToken(
                            whitelistToken,
                            amountOut
                        );
                    }
                }
            }

            emit ReceivedFunds(
                address(this),
                whitelistToken,
                balance,
                outgoingTokens
            );
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function emergencyWithdraw() external {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send ether");
    }

    function emergencyWithdrawToken(address token) external {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, balance);
    }

    fallback() external payable {}

    receive() external payable {}
}
