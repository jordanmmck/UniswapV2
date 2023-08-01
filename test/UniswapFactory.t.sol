// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapFactory.sol";
import "../src/UniswapPair.sol";

contract UniswapFactoryTest is Test {
    UniswapFactory public uniswapFactory;
    UniswapPair public uniswapPair;

    address public alice = address(0x1);
    address public bob = address(0x2);

    address public tokenA = address(0x4);
    address public tokenB = address(0x5);

    function setUp() public {
        uniswapFactory = new UniswapFactory(alice);
    }

    function testCreatePair() public {
        address pair = uniswapFactory.createPair(tokenA, tokenB);
        assertEq(uniswapFactory.getPair(tokenA, tokenB), pair);
    }

    function testCreatePairTestLength() public {
        uniswapFactory.createPair(tokenA, tokenB);
        assertEq(uniswapFactory.allPairsLength(), 1);
    }

    function testSetFeeRecipient() public {
        vm.prank(alice);
        uniswapFactory.setFeeRecipient(bob);
        assertEq(uniswapFactory.feeRecipient(), bob);
    }

    function testSetFeeRecipientSetter() public {
        vm.prank(alice);
        uniswapFactory.setFeeRecipientSetter(bob);
        assertEq(uniswapFactory.feeRecipientSetter(), bob);
    }
}
