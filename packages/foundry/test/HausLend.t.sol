// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/MockPropertyOracle.sol";
import "../contracts/LoanProtocol.sol";
import "../contracts/MockPriceOracle/MockV3Aggregator.sol";
import "../contracts/MockPriceOracle/MockLinkToken.sol";
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

    function setUp() public {
        weth = new WETH();
        propertyNFT = new PropertyNFT();
        propertyOracle = new MockPropertyOracle(propertyNFT);
        priceOracle = new MockV3Aggregator(18, 1400000000000000000000);
        HausLend = new LoanProtocol(escrow, propertyOracle, propertyNFT);
        weth.mint(alice, 1000 ether);
        propertyNFT.mint(bob, 0);
        HausLend.unpause();

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

    function test_expiryLiquidation() public {
        startHoax(carlos);
    }

    function test_underCollateralizedLiquidation() public {
        startHoax(carlos);
    }

    function test_extendDuration() public {
        startHoax(alice);
    }

    function test_repayLoanPartial() public {
        startHoax(bob);
    }

    function test_repayLoanFull() public {
        startHoax(bob);
    }

    function test_acceptLoan() public {
        startHoax(bob);
    }

    function test_pause() public {}

    function updateOracles() private {
        propertyOracle.updatePropertyPrice(0, 10000000);
        HausLend.updateOracles(weth, priceOracle);
    }
}

contract WETH is ERC20("Wrapped ETH", "WETH") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract PropertyNFT is ERC721("PropertyNFt", "PROP") {
    function mint(address to, uint256 id) public {
        _mint(to, id);
    }
}

