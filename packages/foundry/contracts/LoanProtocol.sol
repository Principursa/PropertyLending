//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

contract LoanProtocol {
    struct LoanTerms {
        uint interestRate;

    }
    mapping (address=>LoanTerms) testmap;
}