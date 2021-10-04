pragma solidity ^0.8.0;

import "./camcoin.sol";

contract Loan {

// Struct to store loan data
  struct LoanInfo {
    address lentBy;
    address requestedBy;
    uint256 id;
    uint256 amountLent;
    uint256 loanInterest;
    uint256 collateralOwed;
    uint256 loanTimeSpan;
    uint256 loanStartTime;
    bool loanOffered;
  }

// Array to store loans
  uint[] activeRO;
  uint[] loansTaken;
  uint[] loansClosed;
// Mappings to store active offers/requests
  mapping (uint => LoanInfo) activeRequest;
  mapping (uint => LoanInfo) activeOffer;
// Mappings to store active taken loans;
  mapping (uint => LoanInfo) activeLoan;
// Mapping to store closed loans
  mapping (uint => LoanInfo) closedLoan;

// Events
  event loanOffered(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanRequested(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanTaken(uint256 _amount, uint256 _interest, uint256 _collateral);
  event loanRepayed(uint256 _amount, uint256 _interest, uint256 _collateral);

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
    activeOffer[loanId] = (LoanerInfo(msg.sender, 0, loanId, amount, interest, collateral, time, 0, true));
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

    activeRequest[loanId] = (LoanInfo(0, msg.sender, loanId, amount, interest, collateral, time, 0, false));
    activeRO.push(loanId);

    loanId += 1;
    borrowerToken.transferFrom(msg.sender, address(this), collateral);
    emit loanRequested(amount, interest, collateral);
  }

// Funciton to allow users to take an offered loan - transfers amount from smart contract to borrower
  function takeLoan(uint takenLoanId) external payable {
    CamCoin borrowerToken = CamCoin(msg.sender);
    CamCoin lenderToken = CamCoin(activeOffer[takenLoanId].lentBy);

    activeLoan[takenLoanId] = activeOffer[takenLoanId];
    delete(activeOffer[takenLoanId]);
    loansTaken.push(loanId);
    activeRO = deleteFromArray(loanId, activeRO);

    activeLoan[takenLoanId].loanStartTime = now;
    activeLoan[takenLoanId].requestedBy = msg.sender;

    require(borrowerToken.balanceOf(msg.sender) >= activeLoan[takenLoanId].collateralOwed);
    borrowerToken.transferFrom(msg.sender, address(this), activeLoan[takenLoanId].collateralOwed);
    lenderToken.transfer(msg.sender, activeLoan[takenLoanId].amountLent);
    emit loanTaken(uint256 activeLoan[takenLoanId].amountLent, uint256 activeLoan[takenLoanId].loanInterest, uint256 activeLoan[takenLoanId].collateralOwed);
  }

// Function to allow users to accept a loan request - transfers amount from user to borrower
  function offerLoan(uint requestTakenId) external {
    CamCoin borrowerToken = CamCoin(activeRequest[requestTakenId].requestedBy);
    CamCoin lenderToken = CamCoin(msg.sender);

    activeLoan[requestTakenId] = activeRequest[requestTakenId];
    delete(activeRequest[requestTakenId]);
    loansTaken.push(loanId);
    activeRO = deleteFromArray(loanId, activeRO);

    activeLoan[requestTakenId].loanStartTime = now;
    activeLoan[requestTakenId].lentBy = msg.sender;

    require(lenderToken.balanceOf(msg.sender) >= activeRequestTaken[requestTakenId].amountRequested);
    lenderToken.transfer(activeLoan[requestTakenId].requestedBy, activeLoan[requestTakenId].amountRequested);
    emit loanOffered(uint256 activeLoan[requestTakenId].amountRequested, uint256 activeLoan[requestTakenId].loanInterest, uint256 activeLoan[requestTakenId].collateralOwed);
  }

  function repayLoan(uint loanId) external{
    CamCoin borrowerToken = CamCoin(msg.sender);
    CamCoin lenderToken = CamCoin(activeLoan[loanId].lentBy);

    require(borrowerToken.balanceOf(msg.sender) >= totalPayment); // change this - needs to include calcualted interest

    // transfer from borrower to loaner
    borrowerToken.transfer(lenderToken, totalPayment);
    // transfer collateral from contract back to borrower
    transfer(borrowerToken, activeLoan[loanId].collateralOwed);
    // move loan id from active to closed
    loansClosed.push(loanId);
    loansTaken = deleteFromArray(loanId, loansTaken);

    // remove from activeLoan
    delete(activeLoan[loanId]);
    // emit repayment
    emit loanRepayed(uint256 activeLoan[requestTakenId].amountRequested, uint256 activeLoan[requestTakenId].loanInterest, uint256 activeLoan[requestTakenId].collateralOwed);
  }

  function checkLoanTime(uint loanId) view internal{
    // check current time - loan time < loan loan span
    uint timeSpan = activeLoan[loanId].loanTimeSpan * 60 * 60;
    // if yes transfer collateral to loaner and everything that can be recovered -> add loan to closed
    // if no end
    if ((time - activeLoan[loanId].loanStartTime) > timeSpan) {
      transfer(activeLoan[loanId].collateralOwed, activeLoan[loanId].lentBy);
      loansClosed.push(loanId);
      loansTaken = deleteFromArray(loanId, loansTaken);
      delete(activeLoan[loanId]);
      emit loanDefaulted(uint256 activeLoan[requestTakenId].amountRequested, uint256 activeLoan[requestTakenId].loanInterest, uint256 activeLoan[requestTakenId].collateralOwed);
    }
  }

  function withdrawLoanOffer(uint loanId) external {
    transfer(activeOffer[loanId].amountLent, msg.sender);
    // close loan id
    delete(activeOffer[loanId]);
    activeRO = deleteFromArray(loanId, activeRO);

    // transfer tokens offered back to owner
  }

  function withdrawLoanRequest(uint loanId) external {
    transfer(activeRequest[loanId].collateralOwed, msg.sender);
    // close loan id
    delete(activeRequest[loanId]);
    activeRO = deleteFromArray(loanId, activeRO);

    // transfer collateral back to borrower
  }

  function deleteFromArray(uint valueToDelete, uint[] array) returns(uint[]) internal {
    for (int i = 0; i < array.length; i++) {
      if (array[i] == valueToDelete) {
        array[i] = array.length - 1;
        array.pop();
      }
    }
    return array;
  }

  function getRequestedLoanDetails(uint loanId) view returns(LoanInfo) external {
    return activeRequest[loanId];
  }

  function getOfferedLoanDetails(uint loanId) view returns(LoanInfo) external {
    return activeOffer[loanId];
  }

  function getActiveLoanDetails(uint loanId) view returns(LoanInfo) external {
    return activeLoan[loanId];
  }

  function getClosedLoanDetails(uint loanId) view returns(address, address, uint256, uint256, uint256, uint256, uint256, bool) external {
    LoanInfo loan = closedLoan[loanId];
    return loan.lentBy, loan.requestedBy, loan.amountLent, loan.loanInterest, loan.collateralOwed, loanTimeSpan, loanStartTime, loanOffered;
  }

  function getROLoansId() view returns (uint[]) {
    return activeRO;
  }

  function getAcitveLoansId() view returns (uint[]) {
    return activeLoan;
  }

  function getROLoansId() view returns (uint[]) {
    return closedLoan;
  }
}


// SPDX-License-Identifier: GPL-1.0-or-later
