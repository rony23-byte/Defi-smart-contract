//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

 contract Loan{
    IERC20 public collateralToken;
    IERC20 public borrowedToken;
    uint256 public collateralAmount;
    uint256 public borrowedAmount;
    uint256 public interestRate;
    uint256 public loanDuration;
    uint256 public loanStartTime;
    address public borrower;
    address public lender;
    bool public isClosed;

    event LoanOpened(address borrower, address lender, uint256 collateralAmount, uint256 borrowedAmount, uint256 interestRate, uint256 loanDuration);

    event LoanClosed(address borrower, address lender, uint256 repaymentAmount);

    constructor(IERC20 _collateralToken, IERC20 _borrowedToken, uint256 _collateralAmount, uint256 _borrowedAmount, uint256 _interestRate, uint256 _loanDuration) {
        collateralToken = _collateralToken;
        borrowedToken = _borrowedToken;
        collateralAmount = _collateralAmount;
        borrowedAmount = _borrowedAmount;
        interestRate = _interestRate;
        loanDuration = _loanDuration;
        borrower = msg.sender;
    }
      function approveLoan() public {
        require(msg.sender == lender, "Only the lender can approve the loan.");
        require(isClosed == false, "Loan is already closed.");

        uint256 collateralValue = collateralToken.balanceOf(address(this));
        uint256 borrowedValue = borrowedToken.balanceOf(address(this));
        uint256 requiredCollateral = borrowedValue * interestRate / 100;
        require(collateralValue >= requiredCollateral, "Loan requires over-collateralization.");

        loanStartTime = block.timestamp;
        borrowedToken.transfer(borrower, borrowedAmount);
        lender = address(0);
        emit LoanOpened(borrower, msg.sender, collateralAmount, borrowedAmount, interestRate, loanDuration);
    }

    function repayLoan() public {
        require(msg.sender == borrower, "Only the borrower can repay the loan.");
        require(isClosed == false, "Loan is already closed.");
        require(block.timestamp >= loanStartTime + loanDuration, "Loan duration has not yet expired.");

        uint256 repaymentAmount = borrowedAmount * (100 + interestRate) / 100;
        borrowedToken.transferFrom(msg.sender, address(this), repaymentAmount);
        collateralToken.transfer(borrower, collateralAmount);
        isClosed = true;
        emit LoanClosed(borrower, lender, repaymentAmount);
    }

    function cancelLoan() public {
        require(msg.sender == borrower, "Only the borrower can cancel the loan.");
        require(isClosed == false, "Loan is already closed.");
        collateralToken.transfer(borrower, collateralAmount);
        borrowedToken.transfer(lender, borrowedAmount);
        isClosed = true;
        emit LoanClosed(borrower, lender, 0);
    }

    function setLender(address _lender) public {
        require(lender == address(0), "Lender has already been set.");
        lender = _lender;
    }


 }
