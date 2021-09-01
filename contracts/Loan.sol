pragma solidity ^0.8.0;

import "./camcoin.sol";

contract Loan {
  // Store data for loans being offered
  mapping (uint => address) lentBy;
  mapping (uint => uint) amountLent;
  mapping (uint => uint) loanInterest;
  mapping (uint => uint) collateralOwed;
  // Store data for loans being requested
  mapping (uint => address) requestedBy;
  mapping (uint => uint) amountRequested;
  mapping (uint => uint) interestRequested;
  mapping (uint => uint) collateralRequested
  ;
  mapping (address => mapping(address => uint)) loanedToAddress;
  mapping (address => mapping(address => uint)) outstandingInterest;

  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanTaken(uint256 _amount, uint256 _interest, uint256 _collateral);

  uint256 private loanId = 0;
  uint256 private requestId = 0;

  function lend(address lender, uint256 amount, uint256 interest) external {
    CamCoin lenderToken = CamCoin(lender);

    uint allowance = lenderToken.allowance(lender, msg.sender);
    require(lenderToken.balanceOf(lender) >= amount, "You do not have enough tokens to lend this amount");
    require(allowance >= amount, "You cannot lend that amount");
    require(amount >= 0, "You must lend a non 0 amount");

    uint collateral = amount / 100000;
    lentBy[loanId] = lender;
    amountLent[loanId] = amount;
    loanInterest[loanId] = interest;
    collateralOwed[loanId] = collateral;
    loanId += 1;
    lenderToken.transferFrom(lender, address(this), amount);
    emit loanOffered(amount, interest, collateral);
  }

  function requestLoan(address borrower, uint256 amount, uint interest, uint collateral) external {
    CamCoin borrowerToken = CamCoin(borrower);

    uint maxLoan = collateral * 100000;
    require(borrowerToken.balanceOf(borrower) >= collateral);
    require(amount <= totalLoanPool, "You cannot loan more than is available");
    require(amount <= maxLoan, "You have insufficient collateral for this loan");
    require(amount >= 0, "You must loan a non 0 amount");
    require(amount <= 100000000, "Loan cannot exceed max supply");

    requestedBy[requestId] = borrower;
    amountRequested[requestId] = amount;
    interestRequested[requestId] = interest;
    collateralRequested[requestId] = collateral;
    requestId += 1;
    emit loanRequested(amount, interest, collateral);
  }

  function takeLoan(address borrower, uint takenLoanId) external payable {

  }

  function repayLoan

  function withdrawLoanOffer

  function withdrawLoanRequest

  function checkCollateral

  function transferCollateral
}

// SPDX-License-Identifier: GPL-1.0-or-later
