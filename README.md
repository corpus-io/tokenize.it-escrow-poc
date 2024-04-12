# Escrow POC

This is a demonstration of how a TimelockController can be used to create an escrow that belongs to a user, but can only be accessed by that user after a certain amount of time has passed.
Other users are given an allowance, so they can withdraw the funds from the escrow before the time has passed.

## How to use

Read the tests in `test/Escrow.test.sol` to see how the escrow can be used.
Execute the tests by running `forge test`.

## More info

More internal documentation can be found [here](https://docs.google.com/document/d/1piOpcFwIuEtTMrW-oRRU7JYnDzDu_Z4MT8tFT14POQk/edit).
