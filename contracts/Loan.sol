pragma solidity ^0.8.0;

import "./camcoin.sol";

contract Loan is CamCoin {

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
  event loanDefaulted(uint256 _amount, uint256 _interest, uint256 _collateral);

//Variables
  uint256 private loanId = 0;

// Function that will allow user to list a loan that can be taken - transfers the amount offered to smart contract
  function loanOffer(uint256 amount, uint256 interest, uint timespan) external {
    CamCoin lenderToken = CamCoin(msg.sender);

    uint allowance = lenderToken.allowance(msg.sender, address(this));
    require(lenderToken.balanceOf(msg.sender) >= amount, "You do not have enough tokens to lend this amount");
    require(allowance >= amount, "You cannot lend that amount");
    require(amount >= 0, "You must lend a non 0 amount");

    uint collateral = amount / 100000;
    activeOffer[loanId] = (LoanInfo(msg.sender, address(0), loanId, amount, interest, collateral, timespan, 0, true));
    activeRO.push(loanId);

    loanId += 1;
    lenderToken.transferFrom(msg.sender, address(this), amount);
    emit loanOffered(amount, interest, collateral);
  }

// Function that allows users to post a loan request and transfers collateral to the smart contract
  function requestLoan(uint256 amount, uint interest, uint collateral, uint timespan) external {
    CamCoin borrowerToken = CamCoin(msg.sender);

    uint maxLoan = collateral * 10;
    require(borrowerToken.balanceOf(msg.sender) >= collateral);
    require(amount <= maxLoan, "You have insufficient collateral for this loan");
    require(amount >= 0, "You must loan a non 0 amount");
    require(amount <= 100000000, "Loan cannot exceed max supply");

    activeRequest[loanId] = (LoanInfo(address(0), msg.sender, loanId, amount, interest, collateral, timespan, 0, false));
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

    activeLoan[takenLoanId].loanStartTime = block.timestamp;
    activeLoan[takenLoanId].requestedBy = msg.sender;

    require(borrowerToken.balanceOf(msg.sender) >= activeLoan[takenLoanId].collateralOwed);
    borrowerToken.transferFrom(msg.sender, address(this), activeLoan[takenLoanId].collateralOwed);
    lenderToken.transfer(msg.sender, activeLoan[takenLoanId].amountLent);
    emit loanTaken(activeLoan[takenLoanId].amountLent, activeLoan[takenLoanId].loanInterest, activeLoan[takenLoanId].collateralOwed);
  }

// Function to allow users to accept a loan request - transfers amount from user to borrower
  function offerLoan(uint requestTakenId) external {
    CamCoin lenderToken = CamCoin(msg.sender);

    activeLoan[requestTakenId] = activeRequest[requestTakenId];
    delete(activeRequest[requestTakenId]);
    loansTaken.push(loanId);
    activeRO = deleteFromArray(loanId, activeRO);

    activeLoan[requestTakenId].loanStartTime = block.timestamp;
    activeLoan[requestTakenId].lentBy = msg.sender;

    require(lenderToken.balanceOf(msg.sender) >= activeLoan[requestTakenId].amountLent);
    lenderToken.transfer(activeLoan[requestTakenId].requestedBy, activeLoan[requestTakenId].amountLent);
    emit loanOffered(activeLoan[requestTakenId].amountLent, activeLoan[requestTakenId].loanInterest, activeLoan[requestTakenId].collateralOwed);
  }

  function repayLoan(uint _loanId) external{
    CamCoin contractToken = CamCoin(address(this));
    CamCoin borrowerToken = CamCoin(msg.sender);

    uint currentSpan = (block.timestamp - activeLoan[_loanId].loanStartTime) / 60 / 60 / 24;
    uint totalInterest = activeLoan[_loanId].loanInterest * currentSpan;
    uint totalPayment = activeLoan[_loanId].amountLent + totalInterest;
    require(borrowerToken.balanceOf(msg.sender) >= totalPayment); // change this - needs to include calcualted interest

    // transfer from borrower to loaner
    borrowerToken.transfer(activeLoan[_loanId].lentBy, totalPayment);
    // transfer collateral from contract back to borrower
    contractToken.transfer(msg.sender, activeLoan[_loanId].collateralOwed);
    // move loan id from active to closed
    loansClosed.push(_loanId);
    loansTaken = deleteFromArray(_loanId, loansTaken);

    // remove from activeLoan
    delete(activeLoan[_loanId]);
    // emit repayment
    emit loanRepayed(activeLoan[_loanId].amountLent, activeLoan[_loanId].loanInterest, activeLoan[_loanId].collateralOwed);
  }

  function checkLoanTime(uint _loanId) internal{
    CamCoin contractToken = CamCoin(address(this));
    // check current time - loan time < loan loan span
    uint currentTime = (block.timestamp - activeLoan[_loanId].loanStartTime) / 60 / 60 / 24;
    // if yes transfer collateral to loaner and everything that can be recovered -> add loan to closed
    // if no end
    if (currentTime > activeLoan[_loanId].loanTimeSpan) {
      contractToken.transfer(activeLoan[_loanId].lentBy, activeLoan[_loanId].collateralOwed);
      loansClosed.push(_loanId);
      loansTaken = deleteFromArray(_loanId, loansTaken);
      delete(activeLoan[_loanId]);
      emit loanDefaulted(activeLoan[_loanId].amountLent, activeLoan[_loanId].loanInterest, activeLoan[_loanId].collateralOwed);
    }
  }

  function withdrawLoanOffer(uint _loanId) external {
    CamCoin contractToken = CamCoin(address(this));
    contractToken.transfer(msg.sender, activeOffer[_loanId].amountLent);
    // close loan id
    delete(activeOffer[_loanId]);
    activeRO = deleteFromArray(_loanId, activeRO);

    // transfer tokens offered back to owner
  }

  function withdrawLoanRequest(uint _loanId) external {
    CamCoin contractToken = CamCoin(address(this));
    contractToken.transfer(msg.sender, activeRequest[_loanId].collateralOwed);
    // close loan id
    delete(activeRequest[_loanId]);
    activeRO = deleteFromArray(_loanId, activeRO);

    // transfer collateral back to borrower
  }

  function deleteFromArray(uint valueToDelete, uint[] storage array) internal returns(uint[] memory) {
    for (uint i = 0; i < array.length; i++) {
      if (array[i] == valueToDelete) {
        array[i] = array.length - 1;
        array.pop();
      }
    }
    return array;
  }

  function getRequestedLoanDetails(uint _loanId) external view returns(LoanInfo memory) {
    return activeRequest[_loanId];
  }

  function getOfferedLoanDetails(uint _loanId) view external returns(LoanInfo memory) {
    return activeOffer[_loanId];
  }

  function getActiveLoanDetails(uint _loanId) view external returns(LoanInfo memory) {
    return activeLoan[_loanId];
  }

  /**function getClosedLoanDetails(uint loanId) view external returns(address, address, uint256, uint256, uint256, uint256, uint256, bool) {
    LoanInfo loan = closedLoan[loanId];
    return loan.lentBy, loan.requestedBy, loan.amountLent, loan.loanInterest, loan.collateralOwed, loanTimeSpan, loanStartTime, loanOffered;
  }*/

  function getROLoansId() view external returns (uint[] memory) {
    return activeRO;
  }

  function getActiveLoansId() view external returns (uint[] memory) {
    return loansTaken;
  }

  function getClosedLoansId() view external returns (uint[] memory) {
    return loansClosed;
  }

}


// SPDX-License-Identifier: GPL-1.0-or-later
