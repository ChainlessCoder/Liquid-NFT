#!/usr/bin/python3
import pytest
from brownie import accounts
from brownie.network.state import Chain

@pytest.fixture(scope="module")
def token(MintableERC20Mock):
    return accounts[0].deploy(MintableERC20Mock)

@pytest.fixture(scope="module")
def deep_pool(FeeGeneratingContract, token):
    return accounts[0].deploy(FeeGeneratingContract, token.address)

@pytest.fixture(scope="module")
def liquid_nft(LiquidNFT, deep_pool, token):
    vesting_period = 100
    return accounts[0].deploy(LiquidNFT, token.address, deep_pool.address, vesting_period)

# test mint while FeeGeneratingContract has 0 accumualted fees
def test_mint(liquid_nft, token, accounts):
    token.mint(accounts[0], 1000e18, {'from': accounts[0]})
    token.approve(liquid_nft.address, 10e18, {'from': accounts[0]})
    liquid_nft.mint(accounts[0], 10e18, {'from': accounts[0]})
    liquidity, share, vesitng_start, vesting_end = liquid_nft.getNFTData(1) 
    assert liquidity == 10e18
    assert share == 1e18
    chain = Chain()
    assert vesitng_start == chain.height
    assert vesting_end == chain.height + 100