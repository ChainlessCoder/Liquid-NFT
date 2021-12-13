// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../interfaces/IMintableERC20Mock.sol";


contract MintableERC20Mock is IMintableERC20Mock, ERC20 {
    address private immutable liquidNFT;
    address private erc20Token;

    constructor(
        address _liquidNFT,
        address _erc20Token
    ) ERC20("MockToken", "MOCK") {
        liquidNFT = _liquidNFT;
        erc20Token = _erc20Token;
    }

    function mint(address _to, uint256 _amount) external override returns (bool) {
        _mint(_to, _amount);
        return true;
    }
}