// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
import "../Vesting.sol";

/**
 * @title MockVesting
 * WARNING: use only for testing and debugging purpose
 */
contract MockVesting is Vesting {
    uint256 private mockTime = 0;

    constructor(
        address _token,
        uint256 _start,
        uint256 _duration,
        uint256 _slicePeriodSeconds
    ) Vesting(_token, _start, _duration, _slicePeriodSeconds) {}

    function setCurrentTime(uint256 _time) external {
        mockTime = _time;
    }

    function getCurrentTime() internal view virtual override returns (uint256) {
        return mockTime;
    }
}
