//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol"; 
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol"; 
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol"; 
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; 

contract LoanProtocol is Ownable(msg.sender){
    //implement weth for all eth interactions
    //Add fee mechanisms, possibly both for liquidators and protocol
    //Add permit feature to stop spam and false properties

    //@ERRORS

    error NotOfferedToProperty(uint propertyId, uint loanOffer );
    //@EVENTS

    event PropertySubmission();
    event Liquidation(address owner);
    event LoanStarted();
    event LoanOffered();
    event LoanPaid();
    event Paused();
    event Unpaused();

    bool public isPaused = true;
    uint public listedProperties = 1;
    uint public listedOffers;
    IERC721 public propertyNFTContract;
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
        uint nftID;
        uint amountMaximum;
        IERC20 currency;
        bool avaliable;
        uint minimumHealthFactor;
        uint contractId;
        bool valid;

    }
    //TODO: implement signature mechanisms
    mapping (uint => LoanOffer) openLoans;
    mapping (uint => LoanTerms) loanOnNft;
    mapping (uint=>uint) properties;
    address public escrowAddress;

    constructor(address _escrow) {
        escrowAddress = _escrow;

    }

    function submitNFT(uint collateralId) external {
        require(msg.sender == propertyNFTContract.ownerOf(collateralId));
        properties[listedProperties] = collateralId;
        listedProperties++;

    }
    function proposeLoan(LoanOffer calldata terms) external {
        openLoans[listedOffers] = terms;
        listedOffers++;
        //@TODO: send erc20 to escrow address


    }
    function acceptLoanOffer(uint collateralId, uint offerId, uint amount) external {
        uint _contractId = openLoans[offerId].contractId;
        require(msg.sender == propertyNFTContract.ownerOf(_contractId));
        require(amount <= openLoans[offerId].amountMaximum);
        uint listId = openLoans[offerId].nftID;
        _initiateLoan(offerId,amount);
        //@TODO: transfer nft ownership to escrow

    }

    function callPriceOracle(IERC20 asset) public returns(uint){
        return 1000;//placeholder, replace with chainink mock aggregator

    }
    function callHouseDataOracle() public returns(uint){
        return 1000000;//placeholder

    }

    function _initiateLoan(uint offerId,uint amount) internal {
        LoanOffer storage offer = openLoans[offerId]; 
        require(offer.valid == true);
        LoanTerms memory newTerm;
        newTerm.start = block.timestamp;
        newTerm.amount = amount;
        loanOnNft[openLoans[offerId].nftID] = newTerm;
        openLoans[offerId].valid = false;

    }

    function liquidate(uint listId) external returns(bool){
        IERC20 asset = loanOnNft[listId].currency;
        uint256 endDate = loanOnNft[listId].start + loanOnNft[listId].duration;
        uint assetPrice = callPriceOracle(asset);
        uint collateralPrice = callHouseDataOracle();
        uint assetVaulation = assetPrice * loanOnNft[listId].amount;
        uint healthFactor = loanOnNft[listId].minimumHealthFactor;
        if(block.timestamp > endDate){
            _liqLogic();
            return true;
        }
        if(healthLogic() == true){ //handle health factor stuff
            _liqLogic();
            return true;
        }
        return false;


    }

    function healthLogic() public returns(bool){

    }
    function _liqLogic() internal {

    }
    function extendDuration() external {

    }
    function repayLoan(uint listId,uint inputAmount) external {
        require(inputAmount > 0);
        LoanTerms storage term = loanOnNft[listId];
        require(loanOnNft[listId].status == LoanStatus.ONGOING);
        uint interest = term.interestRate;
        uint termAmount = term.amount;


    }
    function pause() external onlyOwner{
        isPaused = true;

    }
    function unpause() external onlyOwner{
        isPaused = false;

    }


}