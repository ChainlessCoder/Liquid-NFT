// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IFeeGeneratingContract.sol";
import "../../interfaces/IMintableERC20Mock.sol";


contract FeeGeneratingContract is IFeeGeneratingContract {
    using SafeERC20 for IERC20;

    address private liquidNFT;
    address private erc20Token;

    constructor(
        address _erc20Token
    ) {
        erc20Token = _erc20Token;
    }

    function getFeeReserve() external view override returns (uint256 reserve) {
        reserve = IERC20(erc20Token).balanceOf(address(this));
    }

    function redeemFees(address _to, uint256 _shareAmount) external override returns (bool) {
        require(msg.sender == liquidNFT, "Mock: msg.sender must be Liquid NFT contract");
        IERC20(erc20Token).safeTransfer(_to, _shareAmount);
        return true;
    }

    function setLiquidNFTAddress(address _liquidNFT) external override returns (bool) {
        liquidNFT = _liquidNFT;
    }

}