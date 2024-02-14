## Webacy Blast Submission

The following is a modified fork of Uniswap V3 contracts that attempts utilizing core functionality of the Blast Layer2 Rollup to
rebase yield for ETH and their native TBill Stablecoin and incentives in secure interaction within the smart contract ecosystem to create a self sustaining gasless, feeless and slippageless swap ecosystem for users who display good risk management practices with their smart contract hygiene. This works by utilizing the gas payments claim to the governor contract and also configures the token pairs yield to be held to pay the fees and gas and slippage of any trades of any user who scores a high enough risk score on Webacy's service. 

The service check will be configured to check a periodically updated merkle root stored in the governor's contract and whether or not an account exists in said merkle tree to determine whether they're eligible to conduct the swap. This enables an efficient storage mechanism that is scalable with the number of users to Webacy's Risk Score service and helps to make the distribution of free swaps and free gas and slippage sustainable in the long run for users.


## Using solidity interfaces

The Uniswap v3 interfaces are available for import into solidity smart contracts
via the npm artifact `@uniswap/v3-core`, e.g.:

```solidity
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

contract MyContract {
  IUniswapV3Pool pool;

  function doSomethingWithPool() {
    // pool.swap(...);
  }
}

```

## Licensing

The primary license for Uniswap V3 Core is the Business Source License 1.1 (`BUSL-1.1`), see [`LICENSE`](./LICENSE). However, some files are dual licensed under `GPL-2.0-or-later`:

- All files in `contracts/interfaces/` may also be licensed under `GPL-2.0-or-later` (as indicated in their SPDX headers), see [`contracts/interfaces/LICENSE`](./contracts/interfaces/LICENSE)
- Several files in `contracts/libraries/` may also be licensed under `GPL-2.0-or-later` (as indicated in their SPDX headers), see [`contracts/libraries/LICENSE`](contracts/libraries/LICENSE)

### Other Exceptions

- `contracts/libraries/FullMath.sol` is licensed under `MIT` (as indicated in its SPDX header), see [`contracts/libraries/LICENSE_MIT`](contracts/libraries/LICENSE_MIT)
- All files in `contracts/test` remain unlicensed (as indicated in their SPDX headers).
