// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "openzeppelin-contracts/governance/TimelockController.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ERC20MintableByAnyone is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract EscrowTest is Test {
    ERC20MintableByAnyone token;
    TimelockController timelock;

    uint256 public roofPK = 1;
    uint256 public platformColdPK = 2;
    uint256 public emitterPK = 3;

    address public roofAccount = vm.addr(roofPK);
    address public platformColdAccount = vm.addr(platformColdPK);
    address public emitterAccount = vm.addr(emitterPK);
    address public platformHotAccount = address(this);

    function setUp() public {
        vm.warp(1); // otherwise, weird stuff happens

        // create the erc20 token
        token = new ERC20MintableByAnyone("test_token", "TT");

        // create the time lock controller. emitter is proposer and executor, platform is admin
        address[] memory roleHolders = new address[](2);
        roleHolders[0] = emitterAccount;
        roleHolders[1] = platformHotAccount;
        timelock = new TimelockController(
            0 seconds,
            roleHolders,
            roleHolders,
            platformHotAccount // the executing hot wallet is admin for now
        );

        // use admin to give allowances
        address target = address(token);
        uint256 value = 0; // no value
        bytes memory payload = abi.encodeWithSignature(
            "approve(address,uint256)",
            platformColdAccount,
            type(uint256).max
        );
        bytes32 predecessor = 0x0; // no predecessor
        bytes32 salt = 0x0; // no salt
        uint256 delay = 1;

        // get id
        bytes32 id = timelock.hashOperation(
            target,
            value,
            payload,
            predecessor,
            salt
        );

        // propose operation
        assertEq(timelock.isOperation(id), false, "operation should not exist");
        timelock.schedule(target, value, payload, predecessor, salt, delay);
        assertEq(timelock.isOperation(id), true, "operation should exist");
        assertEq(
            timelock.isOperationPending(id),
            true,
            "operation should be pending"
        );

        // execute operation
        // assertEq(
        //     timelock.isOperationPending(id),
        //     true,
        //     "operation should be pending"
        // );
        // increase time by one second
        vm.warp(3);
        assertEq(
            timelock.isOperationReady(id),
            true,
            "operation should be ready"
        );
        timelock.execute(target, value, payload, predecessor, salt);
        assertEq(
            timelock.isOperationDone(id),
            true,
            "operation should be done"
        );

        // mint some tokens to the timelock
        token.mint(address(timelock), 1000);
    }

    function test_platformCanTransfer() public {
        vm.prank(platformColdAccount);
        token.transferFrom(address(timelock), platformColdAccount, 100);
    }
}
