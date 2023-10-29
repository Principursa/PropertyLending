
//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol"; 

contract PropertyNFT is ERC721("PropertyNFt", "PROP") {
    function mint(address to, uint256 id) public {
        _mint(to, id);
    }
}

