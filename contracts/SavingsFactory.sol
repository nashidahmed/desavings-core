// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Savings.sol";

contract SavingsFactory {
    address public immutable owner;

    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call this function");
      _;
    }

    constructor() {
        owner = msg.sender;
    }

    function create(
        address[] memory _whitelistTokens, Savings.TokenDistribution[] memory _tokenDistribution
    ) external {
        new Savings(_whitelistTokens, _tokenDistribution);
    }
}