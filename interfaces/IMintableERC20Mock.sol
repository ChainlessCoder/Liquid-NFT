// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMintableERC20Mock {
    function mint(address _to, uint256 _amount) external returns (bool);
}