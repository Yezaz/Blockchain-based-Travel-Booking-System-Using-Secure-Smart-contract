// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld {
  string public yourName ;

  constructor()  {
    yourName = "Unknown" ;


  }
  function getString() public view returns (string memory) {
    return yourName;
  }

  function setName(string memory nm) public{
    yourName = nm ;
  }



}