# Rebuild Uniswap V2

Your goal is to remake Uniswap V2 core: https://github.com/Uniswap/v2-core/tree/master/contracts

Do not bother with the router or other periphery for now.

## Study

- Fixed Point Arithmetic ([video](https://www.youtube.com/watch?v=YXKDjVcCWyE))
- Constant product AMM ([video](https://www.youtube.com/watch?v=QNPyFs8Wybk))
- Read this audit report ([link](https://github.com/pashov/audits/blob/master/solo/FlorenceFinance-security-review.md))
- Read EIP 3156 ([link](https://eips.ethereum.org/EIPS/eip-3156))

Read the Uniswap V2 Documentation

- Read everything under V2 Protocol ([link](https://docs.uniswap.org/contracts/v2/overview))
- Uniswap V2 Whitepaper, read last ([link](https://uniswap.org/whitepaper.pdf))

Do not get hung up on understanding the math. Just skim the whitepaper in areas that aren’t clear. You’ll learn by doing, not by reading! If you spend more than 3 hours on the paper, force yourself to stop.

## Practice

The following changes must be made:

- [x] You must use solidity 0.8.0 or higher, don’t use SafeMath
- [ ] Use an existing fixed point library, but don’t use the Uniswap one.
- [x] Use Openzeppelin’s or Solmate’s safeTransfer instead of building it from scratch like Unisawp does
- [ ] Instead of implementing a flash swap the way Uniswap does, use EIP 3156. **Be very careful at which point you update the reserves!**

Your unit tests should cover the following cases:

- [x] Adding liquidity
- [x] Swapping
- [x] Withdrawing liquidity
- [ ] Taking a flashloan

Corner cases to watch out for:

- What considerations do you need in your fixed point library? How much of a token with 18 decimals can your contract store?

## to do

- [ ] use fixed-point math lib
- [ ] add flash loan capability (use EIP3156 not the way Uni does it)
- [x] add 30 basis points LP fee
- [x] add non-reentrancy guard
- [ ] add cumulative price oracle stuff
  - i understand this. basic price oracle stuff. i'm ok to lift it from uni.
  - do i even need this?
- [ ] add fee-switch logic

## Notes & Explanations

- [x] locked minimum liquidity
- [x] lock (does not seem to be about reentrancy...)
- [x] square root of product of pools for initial liquidity
- [x] LP fee calculation

### Locked Minimum Liquidity

From the whitepaper:

> Uniswap v2 initially mints shares equal to the geometric mean of the amounts deposited [..] it is possible for the value of a liquidity pool share to grow over time, either by accumulating trading fees or through “donations” to the liquidity pool. In theory, this could result in a situation where the value of the minimum quantity of liquidity pool shares (1e-18 pool shares) is worth so much that it becomes infeasible for small liquidity providers to provide any liquidity. To mitigate this, Uniswap v2 burns the first 1e-15 (0.000000000000001) pool shares that are minted (1000 times the minimum quantity of pool shares), sending them to the zero address instead of to the minter. This should be a negligible cost for almost any token pair.11 But it dramatically increases the cost of the above attack. In order to raise the value of a liquidity pool share to $100, the attacker would need to donate $100,000 to the pool, which would be permanently locked up as liquidity.

Further explained [here](https://ethereum.stackexchange.com/questions/132491/why-minimum-liquidity-is-used-in-dex-like-uniswap)

> In the absence of preset burning, an attacker initializes a pool with 10e-18 weth and 10e-18 dai. This would mint 1LP token which also becomes the total supply. The attacker then transfers 100weth and 100dai to the pair contract and calls the sync function. Now 1LP token is worth 100weth + 100dai. For a new liquidity provider to provide liquidity to the pool, he must now atleast provide 100 eth and 100 dai making it difficult for small liquidity providers to join the pool.

> When an initial amount of 1000LP tokens are burned, there will always be atleast 1000LP tokens. Hence if a donation of 100eth was made, that would represent the increase in the cumulative worth of atleast 1000LP tokens. This would increase the price of a single LP token by just 0.1 max. Hence an attacker would have to spend 1000x more the amount to perform the above attack.

```js
if (_totalSupply == 0) {
  liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
  _mint(address(0), MINIMUM_LIQUIDITY);
} else {
  /* ... */
}
```

### lock

The lock exists to prevent reentrancy. The `mint` and `burn` functions _do not_ themselves allow for reentrancy because they do not call out to any external, non-protocol controlled contracts except via the `balanceOf` call via IERC20 interface which enforces `view`. But, the `swap` function allows any arbitrary external contract to be called with calldata (for flash loan functionality), so the lock is needed to lock access to `mint` and `burn` to prevent an attack from calling `swap` then re-entering into `mint` or `burn` (or `swap`).

### Square Root of Product of Pools for Initial Liquidity

We need to decide some way of minting LP shares as liquidity is added to the pool. A naive approach might be to mint liquidity in proportion to `k` ie. the product of the amount of tokenA and tokenB added. This however, creates a non-linear relationship between liquidity added an LP shares minted.

For example, if you add 10 of each token, you would receive 100 LP shares. But if you add 100 of each token you would receive 10,000 shares. So despite the fact that you added 10x the value of tokens in the latter case, you would have received _1000x_ the LP shares.

By taking the square root of the product of the tokens added, we get a minting curve which is linear with the underlying tokens.

```js
liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
```

### LP fees

The fee to LPs is 30 basis points ie. 0.3% = 3/1000 = 0.003. We can see below the balance for token0 and token1 being calculated _less_ this fee which is applied the inputted amount. Another way to calculate the fee would be to multiply the amount paid by 0.003. That would give a fee amount which we would want to withold. So we could calculate the final balance less the fee as `balance - amountPaid * 0.003`. But one of the problems here is that we may lose some precision on the resulting fee due to the multiplication by 0.003. Instead we can multiply balance by 1000 and subtract the amount paid times 3. This has the same effect. But now the left side of the inequality in the `require` statement is going to be too large by a factor of 1000 times 1000 ie. 1,000,000, so we must multiply the right side of the inequality by `1000**2` as well.

```js
uint256 balance0LessFee = balance0 * 1000 - amount0Paid * 3;
uint256 balance1LessFee = balance1 * 1000 - amount1Paid * 3;
require(
    balance0LessFee * balance1LessFee >= uint256(__reserve0) * uint256(__reserve1) * 1000 ** 2,
    "UniswapPair: K_CONSTANT"
);
```
