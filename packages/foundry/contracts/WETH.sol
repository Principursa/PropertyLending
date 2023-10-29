//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; 

contract WETH is ERC20("Wrapped ETH", "WETH") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

