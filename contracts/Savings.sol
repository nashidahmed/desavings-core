// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./interfaces/ISwapProxy.sol";

contract Savings is AutomationCompatible {
    event ReceivedFunds(
        address indexed savings,
        address tokenIn,
        uint256 amountIn,
        uint256[] amountsOut
    );

    // Goerli token addresses for testing[["0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", 20], ["0x07865c6E87B9F70255377e024ace6630C1Eaa37F", 80]]
    // address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    // address public constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    // address public constant LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    struct TokenDistribution {
        address token;
        uint8 distribution;
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
        upkeepNeeded = address(this).balance > 0;
        return (upkeepNeeded, "");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata performData) external override {
        address whitelistToken = abi.decode(performData, (address));
        uint256 balance = address(this).balance;
        uint256[] memory amounts = new uint256[](tokenDistribution.length);

        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (address(this).balance > 0) {
            for (uint256 x = 0; x < tokenDistribution.length; x++) {
                uint256 amount = (balance * tokenDistribution[x].distribution) /
                    100;
                if (tokenDistribution[x].token == address(0)) {
                    (bool sent, ) = owner.call{value: amount}("");
                    require(sent, "Failed to send ether");
                    amounts[x] = amount;
                } else {
                    amounts[x] = swapProxy.swapExactInputSingle{value: amount}(
                        amount,
                        WETH,
                        tokenDistribution[x].token,
                        owner
                    );
                }
            }

            emit ReceivedFunds(address(this), whitelistToken, balance, amounts);
            // for (int x = 0; x < tokenDistribution.length; x++) {

            // }
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function emergencyWithdraw() external {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send ether");
    }

    fallback() external payable {}

    receive() external payable {}
}
