/**
 * Copyright 2017 Icofunding S.L. (https://icofunding.com)
 * 
 */

contract MintInterface {
  function mint(address recipient, uint amount) returns (bool success);
}

/*
 *  Mint tokens of a linked token
 */
contract WithdrawTokensPreICO {
  address public tokenContract; // address of the token
  uint public vesting; // number of days in which the tokens are going to be blocked
  address public receiver; // receiver of the tokens
  uint public amount; // number of tokens (plus decimals) to be minted

  modifier afterDate() {
    require(now &gt;= vesting);

    _;
  }

  modifier onlyReceiver() {
    require(msg.sender == receiver);

    _;
  }

  function WithdrawTokensPreICO(
    address _tokenContract,
    uint _vesting,
    address _receiver,
    uint _amount
  ) {
    tokenContract = _tokenContract;
    vesting = now + _vesting * 1 days;
    receiver = _receiver;
    amount = _amount;
  }

  // Creates &quot;amount&quot; tokens to &quot;receiver&quot; address
  // Only executed after &quot;vesting&quot; number of days
  // Only executed once
  // Only executed by &quot;receiver&quot;
  function withdraw() public afterDate onlyReceiver {
    require(amount &gt; 0);
    uint tokens = amount;

    amount = 0;
    // mint tokens
    if (!MintInterface(tokenContract).mint(receiver, tokens))
      revert();
  }
}