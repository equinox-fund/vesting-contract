//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct VestingEntry {
    // number of tokens currently vested
    uint256 vested;
    // number of tokens who have been released
    uint256 released;
    // number of tokens currently releasable
    uint256 releasable;
}

contract MemoryLayout is Ownable, ReentrancyGuard {
    /**
     * @notice define when the vesting is starting
     */
    uint256 public start;

    /**
     * @notice define how long last the vesting in seconds
     */
    uint256 public duration;

    /**
     * @notice define release interval in seconds.
     */
    uint256 public slicePeriodSeconds;

    /**
     * @notice define the token address of the vested tokens
     */
    address public tokenContractAddress;

    /**
     * @notice define is the vesting is paused
     */
    bool public isPaused;

    /**
     * @notice define how many tokens are available for vesting
     */
    uint256 public totalVestedTokens;

    /**
     * @notice define how much a given address owns vested tokens
     */
    mapping(address => uint256) public tokensVested;

    /**
     * @notice define how much a given address has released tokens
     */
    mapping(address => uint256) public tokensReleased;
}
