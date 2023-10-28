//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol"; 
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol"; 
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; 

contract LoanProtocol is Ownable(msg.sender){
    //implement weth for all eth interactions
    //Add fee mechanisms, possibly both for liquidators and protocol
    error NotOfferedToProperty(uint propertyId, uint loanOffer );
    bool public isPaused = true;
    uint public listedProperties = 1;
    uint public listedOffers;
    //Implement promissorynote and obligationnote
    struct LoanTerms {
        uint interestRate;
        uint duration;
        uint start;
        address borrower;
        uint amountMaximum;
        uint nftID;
        address currency;
        address lender;

    }
    struct LoanOffer {
        uint interestRate;
        address lender;
        uint duration;
        uint nftID;
        address currency;
        bool avaliable;

    }
    //TODO: implement signature mechanisms
    mapping (uint => LoanOffer) openLoans;
    mapping (address => LoanTerms) loanOnNft;
    mapping (uint=>ERC721) properties;
    address public escrowAddress;

    constructor(address _escrow) {
        escrowAddress = _escrow;

    }

    function submitNFT(ERC721 collateral) external {
        properties[listedProperties] = collateral;
        listedProperties++;

    }
    function proposeLoan(LoanOffer calldata terms) external {
        openLoans[listedOffers] = terms;
        listedOffers++;


    }
    function acceptLoanOffer(uint collateralId, ) external {
        require(properties[collateralId])

    }

    function callPriceOracle() public {

    }
    function callHouseDataOracle() public {

    }

    function _initiateLoan(uint id) internal {
    }

    function liquidate(address nft) external {

    }
    function pause() external onlyOwner{
        isPaused = true;

    }
    function unpause() external onlyOwner{
        isPaused = false;

    }


}