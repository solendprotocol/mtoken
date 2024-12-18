# MToken

This contract manages a vesting and penalty system for a token, MToken, allowing the minting, vesting, and redeeming of tokens under specific conditions. It establishes a VestingManager struct to oversee vesting and penalties, setting a start and end time for the vesting period, along with parameters for penalty calculations. When MToken tokens are minted, they are tied to a VestingManager that records details about the vesting balance, penalty balance, and the parameters for penalty calculation.

The contract provides functionality for redeeming vested tokens, where penalties may apply if redemption occurs before the vesting period ends. The penalty is calculated linearly, decreasing over time until the end of the vesting period.


### Build and Test

`cd contract/`

`sui move build` to build contract

`sui move test` to run tests
