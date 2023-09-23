// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SavingsFactory {
    address public immutable owner;

    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call this function");
      _;
    }

    constructor() {
      owner = msg.sender;
    }
}
