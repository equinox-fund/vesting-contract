//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./MemoryLayout.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vesting is MemoryLayout {
    using SafeERC20 for IERC20;

    event Released(address user, uint256 amount);
    event Revoked(address user);

    /// @notice Vesting contract initialization
    /// @param _tokenContractAddress address of the ERC20 token contract
    /// @param _start Start of vesting (unix timestamp)
    /// @param _duration duration of vesting (in seconds)
    /// @param _slicePeriodSeconds slice period (in seconds).
    constructor(
        address _tokenContractAddress,
        uint256 _start,
        uint256 _duration,
        uint256 _slicePeriodSeconds
    ) {
        require(_duration > 0, "duration must be > 0");
        require(_slicePeriodSeconds >= 1, "slicePeriodSeconds must be >= 1");
        require(
            _tokenContractAddress != address(0x0),
            "Cannot see 0x0 address"
        );

        tokenContractAddress = _tokenContractAddress;
        start = _start;
        duration = _duration;
        slicePeriodSeconds = _slicePeriodSeconds;
        isPaused = false;
    }

    /// @notice pause vesting
    function pauseVesting() external onlyOwner {
        isPaused = true;
    }

    /// @notice unpause vesting
    function unpauseVesting() external onlyOwner {
        isPaused = false;
    }

    /// @notice Return current time
    /// @dev Easiest for testing
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Compute relesable tokens amount for a given user
    /// @param _user given address
    function computeReleasableAmount(address _user)
        public
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        uint256 vested = tokensVested[_user];
        uint256 released = tokensReleased[_user];

        // if user does not have vesting entry
        if (vested == 0) return 0;
        // if the vesting period is over
        if (currentTime >= start + duration) {
            return vested - released;
        } else {
            uint256 timeFromStart = currentTime - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 vestedSeconds = vestedSlicePeriods * slicePeriodSeconds;
            uint256 vestedAmount = (vested * vestedSeconds) / duration;

            return vestedAmount - released;
        }
    }

    /// @notice Return vesting entry for a given user
    /// @param _user user address
    /// @return VestingEntry
    function getVestingEntry(address _user)
        public
        view
        returns (VestingEntry memory)
    {
        // number of tokens currently vested
        uint256 vested = tokensVested[_user];
        // number of tokens who have been released
        uint256 released = tokensReleased[_user];
        // number of tokens currently releasable
        uint256 releasable = computeReleasableAmount(_user);

        return VestingEntry(vested, released, releasable);
    }

    /// @notice Create single vesting entry
    /// @dev If the the vesting entry exist for a given user, we top-up the amount of tokens the owns
    /// @param _user address of users to whom vested tokens are transferred
    /// @param _amount total amount of tokens to be released at the end of the vesting
    function addVestingEntry(address _user, uint256 _amount) public onlyOwner {
        tokensVested[_user] += _amount;
        totalVestedTokens += _amount;
    }

    /// @notice Create multiple vesting entries (batch)
    /// @dev If the the vesting entry exist for a given user, we top-up the amount of tokens the owns
    /// @param _users address of users to whom vested tokens are transferred
    /// @param _amounts total amount of tokens to be released at the end of the vesting
    function addMultipleVestingEntry(
        address[] calldata _users,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_users.length == _amounts.length, "Arguments length mismatch");

        for (uint256 index = 0; index < _users.length; index++) {
            addVestingEntry(_users[index], _amounts[index]);
        }
    }

    /// @notice Revoke vesting entry for a given user
    /// @dev the user cannot release anymore tokens and his vesting is reset
    /// @param _user address of users to whom vested tokens are transferred
    function revokeVestingEntry(address _user) external onlyOwner {
        require(tokensVested[_user] > 0, "vesting entry not found");

        // remove his tokens from the total amount
        totalVestedTokens = totalVestedTokens - tokensVested[_user];
        // set his tokens amount to zero
        tokensVested[_user] = 0;

        emit Revoked(_user);
    }

    /**
     * @notice Release vested amount of tokens.
     * @param amount the amount to release
     */
    function release(uint256 amount) public nonReentrant {
        require(!isPaused, "Vesting paused");
        require(tokensVested[msg.sender] != 0, "No vesting entry");

        uint256 vestedAmount = computeReleasableAmount(msg.sender);
        require(vestedAmount >= amount, "Cannot release tokens");

        tokensReleased[msg.sender] = tokensReleased[msg.sender] + amount;
        totalVestedTokens = totalVestedTokens - amount;

        IERC20(tokenContractAddress).safeTransfer(msg.sender, amount);
        emit Released(msg.sender, amount);
    }
}
