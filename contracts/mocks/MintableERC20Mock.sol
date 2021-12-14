// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../interfaces/IMintableERC20Mock.sol";


contract MintableERC20Mock is IMintableERC20Mock, ERC20 {
    constructor() ERC20("MockToken", "MOCK") {}

    function mint(address _to, uint256 _amount) external override returns (bool) {
        _mint(_to, _amount);
        return true;
    }
}