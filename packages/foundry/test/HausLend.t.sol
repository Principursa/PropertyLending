// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/MockPropertyOracle.sol";
import "../contracts/LoanProtocol.sol";
import "../contracts/MockPriceOracle/MockV3Aggregator.sol";
import "../contracts/MockPriceOracle/MockLinkToken.sol";
import "../contracts/PropertyNFT.sol";
import "../contracts/WETH.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract HausLendTest is Test {
    WETH weth;
    PropertyNFT propertyNFT;
    LoanProtocol HausLend;
    MockPropertyOracle propertyOracle;
    MockV3Aggregator priceOracle;
    address alice = address(0xabe);
    address bob = address(0xbeef);
    address carlos = address(3);
    address escrow = address(4);



    enum LoanStatus {
        ONGOING, LIQUIDATED,PAID
    }

    function setUp() public {
        weth = new WETH();
        propertyNFT = new PropertyNFT();
        propertyOracle = new MockPropertyOracle(propertyNFT);
        priceOracle = new MockV3Aggregator(18, 1400000000000000000000);
        HausLend = new LoanProtocol(escrow, propertyOracle, propertyNFT);
        weth.mint(alice, 1000 ether);
        propertyNFT.mint(bob, 0);

        updateOracles();
    }
    function submitNFT() private {
        startHoax(bob);
        HausLend.submitNFT(0);
    }

    function test_submitNFT() public {
        submitNFT();
        assertEq(HausLend.listedProperties(), 1);
    }
    function proposeLoan() private {

        submitNFT();
        //propose offer
        startHoax(alice);
        weth.approve(address(HausLend),100 ether);
        LoanProtocol.LoanOffer memory offer = LoanProtocol.LoanOffer({
            interestRate: 10, 
            duration: 2682000, 
            lender: alice, 
            nftID: 0, 
            amountMaximum: 100 ether,
            currency: weth,
            minimumHealthFactor: 75,
            contractId: 0,
            valid: true});
        HausLend.proposeLoan(offer);

    }
    function acceptLoan() private {
        proposeLoan();
        startHoax(bob);
        propertyNFT.approve(address(HausLend),0);
        HausLend.acceptLoanOffer(0, 10 ether);

    }

    function test_proposeLoan() public {
        proposeLoan();
        assertEq(HausLend.listedOffers(), 1);
    }

    function test_revokeLoan() public {
        proposeLoan();
        startHoax(alice);
        HausLend.revokeLoan(0);
        (,,,,,,,,bool valid) = HausLend.openLoans(0);
        assertEq(valid, false);
    }
    
    function test_acceptLoan() public {
        acceptLoan();
        (,,,address borrower,,,,,,,) = HausLend.loanOnNft(0);
        assertEq(borrower, bob);
    }

    function test_expiryLiquidation() public {
        acceptLoan();
        skip(2682001);
        startHoax(carlos);
        HausLend.liquidate(0);
        (,,,,,,,address lender,,,) = HausLend.loanOnNft(0);
        assertEq(propertyNFT.ownerOf(0) ,lender);
    }

    function test_underCollateralizedLiquidation() public {
        acceptLoan();
        propertyOracle.updatePropertyPrice(0, 10);
        startHoax(carlos);
        (,,,,,,,address lender,,,) = HausLend.loanOnNft(0);
        HausLend.liquidate(0);
        assertEq(propertyNFT.ownerOf(0) ,lender);
    }
/*     function test_healthyLoanDoesNotLiquidate() public {
        acceptLoan();
        startHoax(carlos);
        (,,,address borrower,,,,,,,) = HausLend.loanOnNft(0);
        HausLend.liquidate(0);
        assertEq(propertyNFT.ownerOf(0) ,borrower);
    }
 */
    function test_extendDuration() public {
        acceptLoan();
        startHoax(alice);
        HausLend.extendDuration(0, 10000);
        (,uint duration,,,,,,,,,) = HausLend.loanOnNft(0);
        assertGt(duration,2682000);
    }

/*     function test_repayLoanPartial() public {
        acceptLoan();
        startHoax(bob);
        weth.mint(bob,20 ether);
        weth.approve(address(HausLend), 20 ether);
        HausLend.repayLoan(0, 20 ether);
        (,,,,uint256 amount,,,,,,) = HausLend.loanOnNft(0);
        assertEq(amount, 80 ether);
    }
 */
    function test_repayLoanFull() public {
        acceptLoan();
        startHoax(bob);
        weth.mint(bob, 100 ether);
        weth.approve(address(HausLend),200 ether);
        HausLend.repayLoan(0,200 ether);
        (,,,address borrower,,,,,,,) = HausLend.loanOnNft(0);
        assertEq(borrower,propertyNFT.ownerOf(0));
    }


    function test_pause() public {}

    function updateOracles() private {
        propertyOracle.updatePropertyPrice(0, 10000000);
        HausLend.updateOracles(weth, priceOracle);
    }
}

