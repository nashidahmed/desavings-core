// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SavingsFactory {

    struct TokenDistribution {
      address token;
      uint256 amount;
    }

    address public immutable owner;
    address[] public whitelistTokens;
    TokenDistribution[] tokenDistribution;

    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call this function");
      _;
    }

    constructor(address[] memory _whitelistTokens, TokenDistribution[] memory _tokenDistribution) {
      owner = msg.sender;
      whitelistTokens = _whitelistTokens;
      tokenDistribution = _tokenDistribution;
    }

    
}
