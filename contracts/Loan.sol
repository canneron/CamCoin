pragma solidity ^0.8.0;

import "./camcoin.sol";

contract Loan {

// Struct to store loan data
  struct LoanInfo {
    address lentBy;
    address requestedBy;
    uint256 amountLent;
    uint256 loanInterest;
    uint256 collateralOwed;
    uint256 loanTimeSpan;
    uint256 loanStartTime;
    bool loanOffered;
  }

// Array to store loans
  uint[] activeRO;
  uint[] closedRO;

// Mappings to store active offers/requests
  mapping (uint => LoanInfo) activeRequest;
  mapping (uint => LoanInfo) activeOffer;
// Mappings to store active taken loans;
  mapping (uint => LoanInfo) activeLoan;
// Mapping to store closed loans
  mapping (uint => LoanInfo) closedLoan;

// Events
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanTaken(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);

//Variables
  uint256 private loanId = 0;

// Function that will allow user to list a loan that can be taken - transfers the amount offered to smart contract
  function loanOffer(uint256 amount, uint256 interest, uint time) external {
    CamCoin lenderToken = CamCoin(msg.sender);

    uint allowance = lenderToken.allowance(msg.sender, address(this));
    require(lenderToken.balanceOf(msg.sender) >= amount, "You do not have enough tokens to lend this amount");
    require(allowance >= amount, "You cannot lend that amount");
    require(amount >= 0, "You must lend a non 0 amount");

    uint collateral = amount / 100000;
    activeOffer[loanId] = (LoanerInfo(msg.sender, 0, amount, interest, collateral, time, 0, true));
    activeRO.push(loanId);

    loanId += 1;
    lenderToken.transferFrom(msg.sender, address(this), amount);
    emit loanOffered(amount, interest, collateral);
  }

// Function that allows users to post a loan request and transfers collateral to the smart contract
  function requestLoan(uint256 amount, uint interest, uint collateral, uint time) external {
    CamCoin borrowerToken = CamCoin(msg.sender);

    uint maxLoan = collateral * 10;
    require(borrowerToken.balanceOf(msg.sender) >= collateral);
    require(amount <= maxLoan, "You have insufficient collateral for this loan");
    require(amount >= 0, "You must loan a non 0 amount");
    require(amount <= 100000000, "Loan cannot exceed max supply");

    activeRequest[loanId] = (LoanInfo(0, msg.sender, amount, interest, collateral, time, 0, false));
    activeRO.push(loanId);

    loanId += 1;
    borrowerToken.transferFrom(msg.sender, address(this), collateral);
    emit loanRequested(amount, interest, collateral);
  }

// Funciton to allow users to take an offered loan - transfers amount from smart contract to borrower
  function takeLoan(uint takenLoanId) external payable {
    CamCoin borrowerToken = CamCoin(msg.sender);
    CamCoin lenderToken = CamCoin(activeOffer[takenLoanId].lentBy);

    activeLoanTaken[takenLoanId] = activeOffer[takenLoanId];
    delete(activeOffer[takenLoanId]);
    activeLoanTaken[takenLoanId].loanStartTime = now;

    require(borrowerToken.balanceOf(msg.sender) >= activeLoanTaken[takenLoanId].collateralOwed);
    borrowerToken.transferFrom(msg.sender, address(this), activeLoanTaken[takenLoanId].collateralOwed);
    lenderToken.transfer(msg.sender, activeLoanTaken[takenLoanId].amountLent);
    emit loanTaken(uint256 activeLoanTaken[takenLoanId].amountLent, uint256 activeLoanTaken[takenLoanId].loanInterest, uint256 activeLoanTaken[takenLoanId].collateralOwed);
  }

// Function to allow users to accept a loan request - transfers amount from user to borrower
  function offerLoan(uint requestTakenId) {
    CamCoin borrowerToken = CamCoin(activeRequest[requestTakenId].requestedBy);
    CamCoin lenderToken = CamCoin(msg.sender);

    activeRequestTaken[requestTakenId] = activeRequest[requestTakenId];
    delete(activeRequest[requestTakenId]);
    activeRequestTaken[requestTakenId].loanStartTime = now;
    activeRequestTaken[requestTakenId].loanedFrom = msg.sender;

    require(lenderToken.balanceOf(msg.sender) >= activeRequestTaken[requestTakenId].amountRequested);
    lenderToken.transfer(activeRequestTaken[requestTakenId].requestedBy, activeRequestTaken[requestTakenId].amountRequested);
    emit loanOffered(uint256 activeRequestTaken[requestTakenId].amountRequested, uint256 interestRequested[requestTakenId], uint256 collateralRequested[requestTakenId]);
  }

  function repayLoan(uint loanId) {
    CamCoin borrowerToken = CamCoin(activeRequestTaken[requestTakenId].requestedBy);
    CamCoin lenderToken = CamCoin(msg.sender);
  }

  function withdrawLoanOffer {

  }

  function withdrawLoanRequest {

  }
}

// SPDX-License-Identifier: GPL-1.0-or-later
