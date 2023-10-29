//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol"; 
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol"; 
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol"; 
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; 
import "./IPropertyOracle.sol";
import "./MockPriceOracle/AggregatorV2V3Interface.sol";

contract LoanProtocol is Ownable(msg.sender){
    //implement weth for all eth interactions
    //Add fee mechanisms, possibly both for liquidators and protocol
    //Add permit feature to stop spam and false properties
    //@TODO: work on the zeroes logic 

    //@ERRORS

    error NotOfferedToProperty(uint propertyId, uint loanOffer );
    error WrongLoanStatus();
    error ContractIsPaused();
    //@EVENTS

    event PropertySubmission();
    event Liquidation(address owner);
    event LoanStarted();
    event LoanOffered();
    event LoanPaid();
    event Paused();
    event Unpaused();
    event TimeIncreased();
    event LoanAmountDecreased();

    bool public isPaused = false;
    uint public listedProperties;
    uint public listedOffers;
    IERC721 public propertyNFTContract;
    IPropertyOracle public propertyOracle;

    enum LoanStatus {
        ONGOING, LIQUIDATED,PAID
        
    }
    //Implement promissorynote and obligationnote
    struct LoanTerms {
        uint interestRate;
        uint duration;
        uint start;
        address borrower;
        uint amount;
        uint nftID;
        IERC20 currency;
        address lender;
        uint contractId;
        uint minimumHealthFactor;
        LoanStatus status;

    }
    struct LoanOffer {
        uint interestRate;
        uint duration;
        address lender;
        uint nftID; //id of the nft on the loan contract
        uint amountMaximum;
        IERC20 currency;
        uint minimumHealthFactor;
        uint contractId; //id of the nft on the nft contract
        bool valid;

    }
    //TODO: implement signature mechanisms
    mapping (uint => LoanOffer) public openLoans;
    mapping (uint => LoanTerms) public loanOnNft;
    mapping (IERC20 => AggregatorV2V3Interface) oracles;
    mapping (uint=>uint) properties;
    address public escrowAddress;

    constructor(address _escrow, IPropertyOracle _propertyOracle,IERC721 _propertyNFTContract) {
        escrowAddress = _escrow;
        propertyOracle = _propertyOracle;
        propertyNFTContract = _propertyNFTContract;


    }

    modifier isNotPaused() {
        if (isPaused == true) {
            revert ContractIsPaused();
        }
        _;
    }

    function updateOracles(IERC20 asset, AggregatorV2V3Interface oracle) external onlyOwner{
        oracles[asset] =  oracle;

    }

    function submitNFT(uint collateralId) external isNotPaused {
        require(msg.sender == propertyNFTContract.ownerOf(collateralId));
        properties[listedProperties] = collateralId;
        listedProperties++;

    }
    function proposeLoan(LoanOffer calldata terms) external isNotPaused{
        require(terms.interestRate <= 100);
        require(terms.minimumHealthFactor <= 100);
        require(msg.sender == terms.lender);
        openLoans[listedOffers] = terms;
        listedOffers++;
        IERC20 asset = terms.currency;
        asset.transferFrom(terms.lender,address(this),terms.amountMaximum);

        //@TODO: send erc20 to escrow address


    }

    function revokeLoan(uint offerId) external{
        LoanOffer storage offer = openLoans[offerId];
        require(offer.valid == true);
        offer.currency.transfer(offer.lender,offer.amountMaximum);
        offer.valid = false;

    }
    function acceptLoanOffer( uint offerId, uint amount) external isNotPaused {
        LoanOffer storage offer = openLoans[offerId];
        uint _contractId = offer.contractId;
        require(offer.valid == true);
        require(msg.sender == propertyNFTContract.ownerOf(_contractId));
        require(offer.lender != msg.sender);
        require(amount <= offer.amountMaximum);
        uint listId = openLoans[offerId].nftID;
        _initiateLoan(offerId,amount);
        //@TODO: transfer nft ownership to escrow

    }


    function _initiateLoan(uint offerId,uint amount) internal isNotPaused{
        LoanOffer storage offer = openLoans[offerId]; 
        LoanTerms memory newTerm;

        newTerm.start = block.timestamp;
        newTerm.amount = amount;
        newTerm.interestRate = offer.interestRate;
        newTerm.duration = offer.duration;
        newTerm.lender = offer.lender;
        newTerm.borrower = propertyNFTContract.ownerOf(offer.contractId);
        newTerm.minimumHealthFactor = offer.minimumHealthFactor;
        newTerm.contractId = offer.contractId;
        newTerm.currency = offer.currency;
        newTerm.status = LoanStatus.ONGOING;
        newTerm.nftID = offer.nftID;


        loanOnNft[openLoans[offerId].nftID] = newTerm;
        openLoans[offerId].valid = false;


        offer.currency.transfer(newTerm.borrower,amount);
        uint256 amountLeftOver = offer.amountMaximum - newTerm.amount;
        if (amountLeftOver > 0) {
            offer.currency.transfer(offer.lender,amountLeftOver);
        }

        propertyNFTContract.transferFrom(newTerm.borrower,address(this),newTerm.nftID);
    }

    function liquidate(uint listId) external isNotPaused returns(bool) {
        LoanTerms storage terms = loanOnNft[listId];
        IERC20 asset = terms.currency;
        uint256 endDate = terms.start + terms.duration;
        (,int price,,,)  = oracles[asset].latestRoundData();
        uint assetPrice = uint(price);
        uint collateralPrice = propertyOracle.getPropertyPrice(terms.contractId);
        uint assetVaulation = assetPrice * terms.amount;
        uint healthFactor = terms.minimumHealthFactor;
        if(block.timestamp > endDate){
            _liqLogic(listId);
            return true;
        }
        if(healthLogic(healthFactor, assetVaulation,collateralPrice) == false){ //handle health factor stuff
            _liqLogic(listId);
            return true;
        }
        return false;


    }

    function healthLogic(uint healthFactor, uint assetVaulation,uint collateralPrice) public returns(bool){
        uint minimumCollateral = assetVaulation * healthFactor / 100;
        console.log(minimumCollateral,"MINIMUM COLLATERAL");
        if (minimumCollateral >= collateralPrice){
            return false;
        }
        return true;

    }
    function _liqLogic(uint listId) internal isNotPaused {
        LoanTerms storage terms = loanOnNft[listId];
        //propertyNFTContract.approve(terms.lender,terms.nftID);
        terms.status = LoanStatus.LIQUIDATED;
        propertyNFTContract.transferFrom(address(this),terms.lender,terms.nftID);

    }
    function extendDuration(uint listId,uint timeAmt) external isNotPaused {
        require(msg.sender == loanOnNft[listId].lender);
        require(timeAmt > 0);
        require(loanOnNft[listId].status == LoanStatus.ONGOING);
        loanOnNft[listId].duration += timeAmt;

    }
    function repayLoan(uint listId,uint inputAmount) external isNotPaused {
        require(inputAmount > 0);
        LoanTerms storage term = loanOnNft[listId];
        require(loanOnNft[listId].status == LoanStatus.ONGOING);
        uint interest = term.interestRate;
        uint principal = term.amount;
        uint intRawAmt = principal * interest / 100; //@TODO: look into division exploit here
        uint amtPlusInterest = intRawAmt + principal;
        if (inputAmount >= amtPlusInterest) {
            term.status = LoanStatus.PAID;
            term.currency.transferFrom(term.borrower,term.lender,amtPlusInterest);
            propertyNFTContract.transferFrom(address(this),term.borrower,term.contractId);

        }
        if (inputAmount < amtPlusInterest) {
            term.amount -= inputAmount;
            term.currency.transferFrom(term.borrower,term.lender,inputAmount);

        }


    }
    function pause() external onlyOwner{
        isPaused = true;
    }
    function unpause() external onlyOwner{
        isPaused = false;
    }


}