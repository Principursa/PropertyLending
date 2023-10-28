//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol"; 

contract LoanProtocol is Ownable{
    //implement weth for all eth interactions
    //Add fee mechanisms, possibly both for liquidators and protocol
    bool public isPaused = true;
    struct LoanTerms {
        uint interestRate;
        uint duration;
        uint start;
        address borrower;
        uint amountMaximum;
        uint nftID;
        address currency;

    }
    struct LoanOffers {
        uint interestRate;
        uint duration;
        uint nftID;
        address currency;

    }
    //TODO: implement signature mechanisms
    mapping (uint => LoanOffers) openLoans;
    mapping (address => LoanTerms) loanOnNft;

    constructor() {
        owner = msg.sender;

    }

    function submitNFT() external {

    }
    function proposeLoan(address lender,address property, LoanTerms terms) external {

    }
    function proposeLoan(address lender) external {
    
    }
    function liquidate() external {

    }
    function pause() external onlyOwner{
        isPaused = true;

    }
    function unpause() external onlyOwner{
        isPaused = false;

    }


}