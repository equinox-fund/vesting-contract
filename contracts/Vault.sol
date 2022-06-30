//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./MemoryLayout.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is MemoryLayout {
    using SafeERC20 for IERC20;

    /// @notice Get the number of tokens who do not belong to user vested entries
    /// @return uint256
    function _getTokenOverflowAmount() private view returns (uint256) {
        return
            IERC20(vestedTokenAddress).balanceOf(address(this)) -
            totalVestedTokens;
    }

    /// @notice Withdraw tokens who do not belong to users
    /// @dev This function is useful to withdraw the token overflow without affecting the vesting.
    function withdrawOverflowTokens() public nonReentrant onlyOwner {
        uint256 overflow = _getTokenOverflowAmount();
        require(overflow > 0, "no overflow tokens");
        IERC20(vestedTokenAddress).safeTransfer(owner(), overflow);
    }

    /// @notice Withdraw all tokens from the contract
    /// @dev Explain to a developer any extra details
    function withdrawAllTokens() public nonReentrant onlyOwner {
        uint256 balance = IERC20(vestedTokenAddress).balanceOf(address(this));
        IERC20(vestedTokenAddress).safeTransfer(owner(), balance);
    }
}
