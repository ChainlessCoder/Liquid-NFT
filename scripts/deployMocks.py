#!/usr/bin/python3
from brownie import accounts, LiquidNFT, FeeGeneratingContract, MintableERC20Mock

def main():
    # deploy mock ERC20 and mint some initial tokens
    token = MintableERC20Mock.deploy({'from': accounts[0]})
    
    # deploy feeGeneratingContract (SOC mock)
    deepPool = FeeGeneratingContract.deploy(token.address, {'from': accounts[0]})

    # deploy liquid NFT 
    liquidNFT = LiquidNFT.deploy(token.address, deepPool.address, 100, {'from': accounts[0]})

    # assign liquid NFT contract address to the FeeGeneratingContract mock contract. Only The liquid NFT can claim rewards from the contract.
    deepPool.setLiquidNFTAddress(liquidNFT.address, {'from': accounts[0]})

    # send some mock ERC20 tokens to the FeeGeneratingContract for the sake of testing
    #token.transfer(deepPool.address, 10e18, {'from': accounts[0]})

    # mint a new Liquid NFT 
    #liquidNFT.mint(accounts[0], 20e18, {'from': accounts[0]})

    # checkout the underlying value of the liquid nft
