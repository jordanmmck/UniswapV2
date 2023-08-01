// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapPair is IERC20 {
    function getTokens() external returns (address, address);
    function getReserves() external returns (uint256, uint256);

    function mint(address to) external returns (uint256 liquidity);
    function swap(address to) external;
    function burn(address to) external returns (uint256, uint256);
}
