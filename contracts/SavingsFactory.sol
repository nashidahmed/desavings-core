// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "./Savings.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

contract SavingsFactory {
    event SavingsCreated(
        address indexed creator,
        address savings,
        address[] whitelistTokens,
        Savings.TokenDistribution[] tokenDistribution
    );
    
    address public immutable owner;
    // LinkTokenInterface public immutable link;
    // KeeperRegistrarInterface public immutable registrar;

    ISwapProxy swapProxy;
    LinkTokenInterface public constant link = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    KeeperRegistrarInterface public constant registrar = KeeperRegistrarInterface(0x57A4a13b35d25EE78e084168aBaC5ad360252467);

    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call this function");
      _;
    }

    constructor(ISwapProxy _swapProxy /* , LinkTokenInterface _link, KeeperRegistrarInterface _registrar */) {
        owner = msg.sender;
        swapProxy = _swapProxy;
        // link = _link;
        // registrar = _registrar;
    }

    function create(
        address[] memory _whitelistTokens, Savings.TokenDistribution[] memory _tokenDistribution, uint96 amount
    ) payable external {
        Savings newSavings = new Savings(swapProxy, msg.sender, _whitelistTokens, _tokenDistribution);
        emit SavingsCreated(msg.sender, address(newSavings), _whitelistTokens, _tokenDistribution);        

        RegistrationParams memory params = RegistrationParams(
            "My savings",
            "0x",
            address(newSavings),
            500000,
            msg.sender,
            "0x",
            "0x",
            amount
        );

        link.transferFrom(msg.sender, address(this), amount);
        link.approve(address(registrar), amount);
        registrar.registerUpkeep(params);
    }
}