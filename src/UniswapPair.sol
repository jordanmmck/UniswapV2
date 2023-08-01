// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {console} from "@forge-std/console.sol";

contract UniswapPair is ERC20, ReentrancyGuard {
    address public factory;
    address public token0;
    address public token1;

    uint128 private _reserve0;
    uint128 private _reserve1;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    constructor() ERC20("UniswapPair", "UNI") {
        factory = msg.sender;
    }

    function getReserves() public view returns (uint128, uint128) {
        return (_reserve0, _reserve1);
    }

    function getTokens() public view returns (address, address) {
        return (token0, token1);
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapPair: FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    function _update(uint256 balance0, uint256 balance1) private {
        require(balance0 <= type(uint128).max && balance1 <= type(uint128).max, "UniswapPair: OVERFLOW");
        _reserve0 = uint128(balance0);
        _reserve1 = uint128(balance1);
    }

    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint128 __reserve0, uint128 __reserve1) = getReserves();
        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        uint256 depositAmount0 = balance0 - __reserve0;
        uint256 depositAmount1 = balance1 - __reserve1;

        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(depositAmount0 * depositAmount1) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(depositAmount0 * _totalSupply / __reserve0, depositAmount1 * _totalSupply / __reserve1);
        }

        require(liquidity > 0, "UniswapPair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
        _update(balance0, balance1);
    }

    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        // (uint128 _reserve0, uint128 _reserve1) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        uint256 _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "UniswapPair: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        SafeERC20.safeTransfer(IERC20(_token0), to, amount0);
        SafeERC20.safeTransfer(IERC20(_token1), to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
    }

    function swap(uint256 amount0Req, uint256 amount1Req, address to, bytes calldata data) external nonReentrant {
        require(amount0Req > 0 || amount1Req > 0, "UniswapPair: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint128 __reserve0, uint128 __reserve1) = getReserves();
        require(amount0Req < __reserve0 && amount1Req < __reserve1, "UniswapPair: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        if (amount0Req > 0) SafeERC20.safeTransfer(IERC20(token0), to, amount0Req);
        if (amount1Req > 0) SafeERC20.safeTransfer(IERC20(token1), to, amount1Req);
        // we need to implement the flash loan spec here. we need a flash loan receiver interface.
        if (data.length > 0) {}
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // amount of each token paid is erc20 balance - the reserve + amount requested (because we've already sent that out)
        uint256 amount0Paid = balance0 > __reserve0 - amount0Req ? balance0 - (__reserve0 - amount0Req) : 0;
        uint256 amount1Paid = balance1 > __reserve1 - amount1Req ? balance1 - (__reserve1 - amount1Req) : 0;
        require(amount0Paid > 0 || amount1Paid > 0, "UniswapPair: INSUFFICIENT_INPUT_AMOUNT");

        // fee to LPs is 0.3% of the amount paid ie. 30 basis points
        uint256 balance0LessFee = balance0 * 1000 - amount0Paid * 3;
        uint256 balance1LessFee = balance1 * 1000 - amount1Paid * 3;
        // invariant check. multiply product of reserves by 1000**2 because balances are each multiplied by 1000
        require(
            balance0LessFee * balance1LessFee >= uint256(__reserve0) * uint256(__reserve1) * 1000 ** 2,
            "UniswapPair: K_CONSTANT"
        );

        _update(balance0, balance1);
    }
}
