// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./UniswapPair.sol";

contract UniswapFactory {
    address public feeRecipient;
    address public feeRecipientSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 index);

    constructor(address _feeRecipientSetter) {
        feeRecipientSetter = _feeRecipientSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "UniswapFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // lexical ordering
        require(token0 != address(0), "UniswapFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapFactory: PAIR_EXISTS");

        // deploy pair
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new UniswapPair{salt: salt}());

        // initialize pair
        UniswapPair(pair).initialize(token0, token1);

        // update accounting
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length - 1);
    }

    function setFeeRecipient(address _feeRecipient) public {
        require(msg.sender == feeRecipientSetter, "UniswapFactory: not feeRecipientSetter");
        feeRecipient = _feeRecipient;
    }

    function setFeeRecipientSetter(address _feeRecipientSetter) public {
        require(msg.sender == feeRecipientSetter, "UniswapFactory: not feeRecipientSetter");
        feeRecipientSetter = _feeRecipientSetter;
    }
}
