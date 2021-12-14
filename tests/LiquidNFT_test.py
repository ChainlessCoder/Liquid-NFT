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

def test_get_underlying_value(liquid_nft):
    underlying_value = liquid_nft.getUnderlyingValue(1)
    assert underlying_value == 10e18

# get underlying value after fees get accumulated inside FeeGeneratingContract
def test_get_new_underlying_value(liquid_nft, deep_pool, token):
    token.transfer(deep_pool.address, 20e18, {'from': accounts[0]})
    underlying_value = liquid_nft.getUnderlyingValue(1)
    assert underlying_value == 30e18

def test_get_underlying_value_after_new_mint(liquid_nft, deep_pool, token):
    token.mint(accounts[1], 1000e18, {'from': accounts[0]})
    token.approve(liquid_nft.address, 10e18, {'from': accounts[1]})
    liquid_nft.mint(accounts[1], 10e18, {'from': accounts[1]})
    liquidity1, share1, _, _ = liquid_nft.getNFTData(1) 
    liquidity2, share2, _, _ = liquid_nft.getNFTData(2) 
    assert share1 == 1e18 
    assert share2 == 1e18 * 10e18 / (2*20e18)
    underlying_value1 = liquid_nft.getUnderlyingValue(1)
    underlying_value2 = liquid_nft.getUnderlyingValue(2)
    assert underlying_value1 == liquidity1 + (20e18 * share1 / (share1 + share2))
    assert underlying_value2 == liquidity2 + (20e18 * share2 / (share1 + share2))