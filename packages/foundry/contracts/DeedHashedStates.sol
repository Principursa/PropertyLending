// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DeedHashedStates {

    enum TokenState {
      InitialSetup,
      InitialDocuments,
      TitleAndEscrow,
      InspectionsAndDisclosures,
      ClosingStatements,
      Payment,
      DeedAndFinalDocuments,
      Complete,
      Cancelled
    }

}