//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPropertyOracle {
    function getPropertyPrice(uint nftId)external returns(uint256 price);
    function updatePropertyPrice(uint nftId, uint price) external;
}