// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapFactory.sol";
import "../src/UniswapPair.sol";
import {IUniswapPair} from "../src/IUniswapPair.sol";
import {TokenA} from "./TokenA.sol";
import {TokenB} from "./TokenB.sol";

contract UniswapPairTest is Test {
    UniswapFactory public uniswapFactory;
    UniswapPair public uniswapPair;

    TokenA public tokenA;
    TokenB public tokenB;

    address public admin = address(0x1);
    address public vitalik = address(0x2);
    address public satoshi = address(0x3);

    address public pair;

    function setUp() public {
        uniswapFactory = new UniswapFactory(admin);

        tokenA = new TokenA();
        tokenB = new TokenB();

        pair = uniswapFactory.createPair(address(tokenA), address(tokenB));
    }

    function testGetPairAndZeroReserves() public {
        (address token0, address token1) = IUniswapPair(pair).getTokens();
        assertEq(token0, address(tokenA));
        assertEq(token1, address(tokenB));

        (uint256 reserve0, uint256 reserve1) = IUniswapPair(pair).getReserves();
        assertEq(reserve0, 0);
        assertEq(reserve1, 0);
    }

    function testMint() public {
        tokenA.mint(vitalik, 1000e18);
        tokenB.mint(vitalik, 1000e18);

        vm.prank(vitalik);
        tokenA.transfer(pair, 1000e18);
        vm.prank(vitalik);
        tokenB.transfer(pair, 1000e18);

        IUniswapPair(pair).mint(vitalik);
        assertEq(IERC20(pair).balanceOf(vitalik), 1000e18 - 1000);
    }

    function testBurn() public {
        tokenA.mint(vitalik, 1000e18);
        tokenB.mint(vitalik, 1000e18);

        vm.prank(vitalik);
        tokenA.transfer(pair, 1000e18);
        vm.prank(vitalik);
        tokenB.transfer(pair, 1000e18);

        IUniswapPair(pair).mint(vitalik);
        assertEq(IUniswapPair(pair).balanceOf(vitalik), 1000e18 - 1000);

        vm.prank(vitalik);
        IUniswapPair(pair).transfer(pair, 500e18);
        IUniswapPair(pair).burn(vitalik);

        assertEq(IUniswapPair(pair).balanceOf(vitalik), 500e18 - 1000);
        assertEq(tokenA.balanceOf(vitalik), 500e18);
        assertEq(tokenB.balanceOf(vitalik), 500e18);
    }

    function testBasicSwap() public {
        tokenA.mint(vitalik, 1000e18);
        tokenB.mint(vitalik, 1000e18);
        tokenA.mint(satoshi, 1e18);

        vm.startPrank(vitalik);
        tokenA.transfer(pair, 1000e18);
        tokenB.transfer(pair, 1000e18);
        IUniswapPair(pair).mint(vitalik);
        vm.stopPrank();

        vm.startPrank(satoshi);

        // swap A for B
        tokenA.transfer(pair, 1e18);
        IUniswapPair(pair).swap(satoshi);
        assertEq(tokenA.balanceOf(satoshi), 0);
        assertEq(tokenB.balanceOf(satoshi), 999000999000999000);

        // swap B for A
        tokenB.transfer(pair, 999000999000999000);
        IUniswapPair(pair).swap(satoshi);
        // due to rounding precision loss we lose 1 wei
        assertEq(tokenA.balanceOf(satoshi), 1e18 - 1);
        assertEq(tokenB.balanceOf(satoshi), 0);

        vm.stopPrank();
    }
}
