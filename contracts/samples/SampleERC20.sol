// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleERC20 is ERC20 {
    constructor() ERC20("SampleERC20", "ERC") {}

    function mintToWallet(address _address, uint256 _amount) external {
        _mint(_address, _amount);
    }
}
