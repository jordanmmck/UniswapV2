// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20("tokenA", "TA") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
