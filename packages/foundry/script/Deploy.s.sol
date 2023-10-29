//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "./DeployHelpers.s.sol";
import "forge-std/Test.sol";
import "../contracts/MockPropertyOracle.sol";
import "../contracts/LoanProtocol.sol";
import "../contracts/MockPriceOracle/MockV3Aggregator.sol";
import "../contracts/MockPriceOracle/MockLinkToken.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../contracts/PropertyNFT.sol";
import "../contracts/WETH.sol";


contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);
        address escrow = address(3);
        WETH weth = new WETH(
        );
         PropertyNFT propertyNFT = new PropertyNFT(
        );
        MockPropertyOracle propertyOracle = new MockPropertyOracle(
            propertyNFT
        );
        MockV3Aggregator priceOracle = new MockV3Aggregator(
            18,1400000000000000000000);
        LoanProtocol hausLoan = new LoanProtocol(
            escrow,propertyOracle,propertyNFT
            //vm.addr(deployerPrivateKey)
        ); 
        console.logString(
            string.concat(
                "HausLoan deployed at: ",
                vm.toString(address(weth))
            )
        );
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}

