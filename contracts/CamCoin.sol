pragma solidity ^0.8.0;

contract CamCoin {

   //Variable Declarations
   uint256 private _totalSupply;
   uint8 private _decimals;
   string private _name;
   string private _symbol;

   //Mappings
   mapping(address => uint256) private _balance;
   mapping(address => mapping(address => uint256)) private _allowed;

   //Events
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender,uint256 _value);

   //Constructor
   constructor() {
     _name = "CamCoin";
     _symbol = "XCAM";
     _decimals = 18;
     _totalSupply = 100000000000000000000000000;

     _balance[msg.sender] = _totalSupply;
     emit Transfer(address(0), msg.sender, _totalSupply);
   }

   //ERC20 Standard Functions
   function totalSupply() external view returns (uint supply) {
     return _totalSupply - _balance[address(0)];
   }

   function balanceOf(address account) external view returns (uint acctBalance) {
     return _balance[account];
   }

   function allowance(address owner, address spender) internal view returns (uint allowanceOf) {
     return _allowed[owner][spender];
   }

   function approve(address delegate, uint256 amount) external returns (bool pass) {
     _allowed[msg.sender][delegate];
     emit Approval(msg.sender, delegate, amount);
     return true;
   }

   function transfer(address recipient, uint256 amount) external returns (bool pass) {
     require(_balance[msg.sender] >= amount);
     _balance[recipient] += amount;
     _balance[msg.sender] -= amount;
     emit Transfer(msg.sender, recipient, amount);
     return true;
   }

   function transferFrom(address owner, address recipient, uint256 amount) external returns (bool pass) {
     require(_balance[owner] >= amount);
     require(_allowed[owner][msg.sender] >= amount);

     _balance[recipient] += amount;
     _balance[owner] -= amount;
     _allowed[owner][msg.sender] -= amount;
     emit Transfer(owner, recipient, amount);
     return true;
   }

   function upAllowance(address spender, uint256 addedValue) external returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] + addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender] - subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
}

// SPDX-License-Identifier: GPL-1.0-or-later
