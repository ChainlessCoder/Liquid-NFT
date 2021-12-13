// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ILiquidNFT {
    function getNFTData(uint256 _tokenID) external view returns (uint256 stakedAmount, uint256 lpShare, uint256 vestingStart, uint256 vestingEnd);
    function getUnderlyingValue(uint256 _tokenID) external view returns (uint256 underlyingNFTValue);
    function getRedeemableTokenAmount(uint256 _tokenID) external view returns (uint256 redeemableAmount);
    function mint(address _to, uint256 _amount) external returns (bool);
    function boost(uint256 _amount, uint256 _tokenID) external returns (bool);
    function redeem(address to, uint256 _percentage, uint256 _nftId) external returns (bool);

    event Staked(address indexed from, uint256 staked, uint256 lp, uint256 nftID);
    event Boosted(address indexed from, uint256 staked, uint256 lp, uint256 nftID);
    event Redeemed(address indexed from, uint256 amount, uint256 nftID);
}