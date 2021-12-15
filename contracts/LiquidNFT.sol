// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './libraries/Math.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IFeeGeneratingContract.sol";
import "../interfaces/ILiquidNFT.sol";

contract LiquidNFT is ILiquidNFT, ERC721 {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    address private token2Stake; // the token used to mint Liquid NFTs
    address private feeGeneratingContract; // the actual DeFi product that generates income
    uint256 private totalReserveShare = 0;
    uint256 private vestingPeriod; // e.g. if set to ~12 months of blocks, NFT gets 100% redeemable after 1 year
    mapping(uint256 => NFTData) private tokenData;

    struct NFTData {
        uint256 liquidity;
        uint256 share;
        uint256 vestingStart;
        uint256 vestingEnd;
    }

    constructor(
        address _token2Stake,
        address _feeGeneratingContract,
        uint256 _vestingPeriod
    ) ERC721("Liquid-NFT", "LNFT") {
        token2Stake = _token2Stake;
        feeGeneratingContract = _feeGeneratingContract;
        vestingPeriod = _vestingPeriod;
    }

    function stake(uint256 _amount) internal returns (uint256 share) {
        require(_amount > 0, "LiquidNFT: Amount too small");
        IERC20 token = IERC20(token2Stake);
        require(token.balanceOf(msg.sender) >= _amount, "LiquidNFT: Amount exceeds balance");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        share = 1e18 * _amount / ((_tokenIds.current() + 1) * token.balanceOf(address(this)));
    }

    function getNFTData(uint256 _tokenID) public view override returns (
        uint256 liquidity,
        uint256 share,
        uint256 vestingStart,
        uint256 vestingEnd) {
            require(_exists(_tokenID), "LiquidNFT: NFT does not exist");
            NFTData memory nft = tokenData[_tokenID];
            liquidity = nft.liquidity;
            share = nft.share;
            vestingStart = nft.vestingStart;
            vestingEnd = nft.vestingEnd;
        }
    
    function share2Amount(uint256 share) internal view returns (uint256 redeemableAmountOfShare) {
        uint256 feeGeneratingContractReserve = IFeeGeneratingContract(feeGeneratingContract).getFeeReserve();
        redeemableAmountOfShare = feeGeneratingContractReserve * share / totalReserveShare;
    }

    // Returns the underlying value of an NFT in terms of token2Stake 
    // Note: This implementation assumes that the fees collected by feeGeneratingContract are also in terms of token2Stake
    function getUnderlyingValue(uint256 _tokenID) public view override returns (uint256 underlyingNFTValue) {
        (uint256 liquidity, uint256 share,,) = getNFTData(_tokenID);
        underlyingNFTValue = liquidity + share2Amount(share);
    }

    function getRedeemableTokenAmount(uint256 _tokenID) public view override returns (uint256 redeemableAmount) {
        (uint256 liquidity, uint256 share, uint256 vestingStart, uint256 vestingEnd) = getNFTData(_tokenID);
        uint256 currentBlock = block.number;
        uint256 upperBoundBlock = currentBlock <= vestingEnd ? currentBlock : vestingEnd;
        uint256 redeemableLiquidity = liquidity * (upperBoundBlock - vestingStart) / vestingPeriod;
        uint256 redeemableShare = share * (upperBoundBlock - vestingStart) / vestingPeriod;
        redeemableAmount = redeemableLiquidity + share2Amount(redeemableShare);
    }

    function mint(address _to, uint256 _amount) public override returns (bool) {
        uint256 share = stake(_amount);
        totalReserveShare += share;
        _tokenIds.increment();
        uint256 newTokenID = _tokenIds.current();
        _safeMint(_to, newTokenID);
        uint256 currentBlock = block.number;
        tokenData[newTokenID] = NFTData(_amount, share, currentBlock, currentBlock + vestingPeriod);
        emit Staked(_to, _amount, share, newTokenID);
        return true;
    }

    function boost(uint256 _amount, uint256 _tokenID) public override returns (bool) {
        uint256 share = stake(_amount);
        totalReserveShare += share;
        uint256 currentBlock = block.number;
        (uint256 NFTLiquidity, uint256 NFTShare,,) = getNFTData(_tokenID);
        tokenData[_tokenID] = NFTData(NFTLiquidity + _amount, NFTShare + share, currentBlock, currentBlock + vestingPeriod);
        emit Boosted(msg.sender, _amount, share, _tokenID);
        return true;
    }

    function redeem(address _to, uint256 _amount, uint256 _tokenID) public override returns (bool) {
        require(_amount > 0, "LiquidNFT: Invalid amount");
        require(msg.sender == ownerOf(_tokenID), "LiquidNFT: Not the owner of the NFT");
        uint256 redeemableAmount = getRedeemableTokenAmount(_tokenID);
        require(_amount <= redeemableAmount, "LiquidNFT: Amount exceeds redeemable amount");

        IERC20 token = IERC20(token2Stake);
        uint256 currentBlock = block.number;
        uint256 dif;
        uint256 dif2share;
        (uint256 NFTLiquidity, uint256 NFTShare, , uint256 vestingEnd) = getNFTData(_tokenID);
        if (NFTLiquidity >= _amount) {
            token.safeTransfer(_to, _amount);
            tokenData[_tokenID] = NFTData(NFTLiquidity - _amount, NFTShare, currentBlock, vestingEnd);
        } else {
            dif = _amount - NFTLiquidity;
            if (NFTLiquidity != 0){
                token.safeTransfer(_to, NFTLiquidity);
            }
            IFeeGeneratingContract(feeGeneratingContract).redeemFees(_to, dif);
            dif2share = NFTShare * dif / (redeemableAmount - NFTLiquidity);
            tokenData[_tokenID] = NFTData(0, NFTShare - dif2share, currentBlock, vestingEnd);
            totalReserveShare -= dif2share;
        }
        emit Redeemed(msg.sender, _amount, _tokenID);
        return true;
    }

}