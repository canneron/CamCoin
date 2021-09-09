pragma solidity ^0.8.0;

import "./camcoin.sol";

contract Loan {
  // Store data for loans being offered
  mapping (uint => address) lentBy;
  mapping (uint => uint) amountLent;
  mapping (uint => uint) loanInterest;
  mapping (uint => uint) collateralOwed;
  mapping (uint => address) loanTime;
  // Store data for loans being requested
  mapping (uint => address) requestedBy;
  mapping (uint => uint) amountRequested;
  mapping (uint => uint) interestRequested;
  mapping (uint => uint) collateralRequested
  mapping (uint => address) loanTimeRequested;
  // Store data for taken loans
  mapping (uint => uint) loanTakenTime;
  mapping (uint => uint) loanTakenTime;

  struct LoanTaken { address addr; }
  struct LoanOffered { address addr; }

  mapping (uint256 => LoanTaken) internal loansTakenByAddress;
  mapping (uint256 => LoanOffered) internal loansOfferedByAddress;

  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanTaken(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);

  uint256 private loanId = 0;
  uint256 private requestId = 0;

  function lend(address lender, uint256 amount, uint256 interest, uint time) external {
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
    loanTime[loanId] = time;

    loanId += 1;
    lenderToken.transferFrom(lender, address(this), amount);
    emit loanOffered(amount, interest, collateral);
  }

  function requestLoan(address borrower, uint256 amount, uint interest, uint collateral, uint time) external {
    CamCoin borrowerToken = CamCoin(borrower);

    uint maxLoan = collateral * 10;
    require(borrowerToken.balanceOf(borrower) >= collateral);
    require(amount <= maxLoan, "You have insufficient collateral for this loan");
    require(amount >= 0, "You must loan a non 0 amount");
    require(amount <= 100000000, "Loan cannot exceed max supply");

    requestedBy[requestId] = borrower;
    amountRequested[requestId] = amount;
    interestRequested[requestId] = interest;
    collateralRequested[requestId] = collateral;
    loanTimeRequested[requestId] = time;
    requestId += 1;

    borrowerToken.transferFrom(borrower, address(this), amount);
    emit loanRequested(amount, interest, collateral);
  }



  function takeLoan(address borrower, uint takenLoanId) external payable {
    CamCoin borrowerToken = CamCoin(borrower);
    CamCoin lenderToken = CamCoin(lentBy[takenLoanId]);

    loansTakenByAddress[takenLoanId].addr = borrower;
    loanTakenTime[takenLoanId] = now;
    require(borrowerToken.balanceOf(borrower) >= collateralOwed[takenLoanId]);
    borrowerToken.transferFrom(borrower, address(this), collateralOwed[takenLoanId]);
    lenderToken.transfer(borrower, amountLent[takenLoanId]);
    emit loanTaken(uint256 amountLent[takenLoanId], uint256 loanInterest[takenLoanId], uint256 loanInterest[takenLoanId]);
  }

  function offerLoan(address lender, uint requestTakenId) {
    CamCoin borrowerToken = CamCoin(requestedBy[requestTakenId]);
    CamCoin lenderToken = CamCoin(lender);

    loansOfferedByAddress[requestTakenId].addr = lender;
    loanOfferedTime[requestTakenId] = now;
    require(lenderToken.balanceOf(lender) >= amountRequested[requestTakenId]);
    borrowerToken.transferFrom(requestedBy[requestTakenId], address(this), collateralRequested[requestTakenId]);
    lenderToken.transfer(requestedBy[requestTakenId], amountRequested[requestTakenId]);
    emit loanOffered(uint256 amountRequested[requestId], uint256 interestRequested[requestTakenId], uint256 collateralRequested[requestTakenId]);
  }

  function repayLoan

  function withdrawLoanOffer

  function withdrawLoanRequest

  function checkCollateral

  function transferCollateral
}

// SPDX-License-Identifier: GPL-1.0-or-later
