// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapPair is IERC20 {
    function getTokens() external returns (address, address);
    function getReserves() external returns (uint256, uint256);

    function price0CumulativeLast() external returns (uint256);
    function price1CumulativeLast() external returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function swap(uint256 amount0Req, uint256 amount1Req, address to, bytes calldata data) external;
    function burn(address to) external returns (uint256, uint256);
}
