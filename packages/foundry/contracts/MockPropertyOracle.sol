//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol"; 
import "./IPropertyOracle.sol";

contract MockPropertyOracle is IPropertyOracle{
    IERC721 propertyNftContract;
    mapping (uint256 => uint256) propertyPrices;
    constructor (IERC721 _propertyNftContract)  {
        propertyNftContract = _propertyNftContract;

    }
     function getPropertyPrice(uint nftId) external returns (uint256){
        uint256 propertyPrice = propertyPrices[nftId];
        return propertyPrice;

     }
     function updatePropertyPrice(uint nftId,uint updatedPrice) external {
        propertyPrices[nftId] = updatedPrice;

     }
}


