/*
 * Safe Math Smart Contract.  Copyright &#169; 2016–2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a8c5c1c3c0c9c1c486dec4c9ccc1c5c1dac7dee8cfc5c9c1c486cbc7c5">[email&#160;protected]</a>&gt;
 */
pragma solidity ^0.4.20;

/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Add two uint256 values, throw in case of overflow.
   *
   * @param x first value to add
   * @param y second value to add
   * @return x + y
   */
  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x &lt;= MAX_UINT256 - y);
    return x + y;
  }

  /**
   * Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param x value to subtract from
   * @param y value to subtract
   * @return x - y
   */
  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x &gt;= y);
    return x - y;
  }

  /**
   * Multiply two uint256 values, throw in case of overflow.
   *
   * @param x first value to multiply
   * @param y second value to multiply
   * @return x * y
   */
  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x &lt;= MAX_UINT256 / y);
    return x * y;
  }
}
/*
 * EIP-20 Standard Token Smart Contract Interface.
 * Copyright &#169; 2016–2018 by ABDK Consulting.
 * Author: Mikhail Vladimirov &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="80ede9ebe8e1e9ecaef6ece1e4e9ede9f2eff6c0e7ede1e9ecaee3efed">[email&#160;protected]</a>&gt;
 */

/**
 * ERC-20 standard token interface, as defined
 * &lt;a href=&quot;https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md&quot;&gt;here&lt;/a&gt;.
 */
contract Token {
  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public view returns (uint256 supply);

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public view returns (uint256 balance);

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public returns (bool success);

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public returns (bool success);

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

  /**
   * Logged when tokens were transferred from one owner to another.
   *
   * @param _from address of the owner, tokens were transferred from
   * @param _to address of the owner, tokens were transferred to
   * @param _value number of tokens transferred
   */
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  /**
   * Logged when owner approved his tokens to be transferred by some spender.
   *
   * @param _owner owner who approved his tokens to be transferred
   * @param _spender spender who were allowed to transfer the tokens belonging
   *        to the owner
   * @param _value number of tokens belonging to the owner, approved to be
   *        transferred by the spender
   */
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}/*
 * Address Set Smart Contract Interface.
 * Copyright &#169; 2017–2018 by ABDK Consulting.
 * Author: Mikhail Vladimirov &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="204d494b4841494c0e564c4144494d49524f5660474d41494c0e434f4d">[email&#160;protected]</a>&gt;
 */

/**
 * Address Set smart contract interface.
 */
contract AddressSet {
  /**
   * Check whether address set contains given address.
   *
   * @param _address address to check
   * @return true if address set contains given address, false otherwise
   */
  function contains (address _address) public view returns (bool);
}
/*
 * Abstract Token Smart Contract.  Copyright &#169; 2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c5a8acaeada4aca9ebb3a9a4a1aca8acb7aab385a2a8a4aca9eba6aaa8">[email&#160;protected]</a>&gt;
 */

/**
 * Abstract Token Smart Contract that could be used as a base contract for
 * ERC-20 token contracts.
 */
contract AbstractToken is Token, SafeMath {
  /**
   * Create new Abstract Token contract.
   */
  function AbstractToken () public {
    // Do nothing
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public view returns (uint256 balance) {
    return accounts [_owner];
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public returns (bool success) {
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance &lt; _value) return false;
    if (_value &gt; 0 &amp;&amp; msg.sender != _to) {
      accounts [msg.sender] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance &lt; _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance &lt; _value) return false;

    allowances [_from][msg.sender] =
      safeSub (spenderAllowance, _value);

    if (_value &gt; 0 &amp;&amp; _from != _to) {
      accounts [_from] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (_from, _to, _value);
    return true;
  }

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);

    return true;
  }

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

  /**
   * Mapping from addresses of token holders to the numbers of tokens belonging
   * to these token holders.
   */
  mapping (address =&gt; uint256) internal accounts;

  /**
   * Mapping from addresses of token holders to the mapping of addresses of
   * spenders to the allowances set by these token holders to these spenders.
   */
  mapping (address =&gt; mapping (address =&gt; uint256)) internal allowances;
}
/*
 * Abstract Virtual Token Smart Contract.
 * Copyright &#169; 2017–2018 by ABDK Consulting.
 * Author: Mikhail Vladimirov &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a3cecac8cbc2cacf8dd5cfc2c7cacecad1ccd5e3c4cec2cacf8dc0ccce">[email&#160;protected]</a>&gt;
 */


/**
 * Abstract Token Smart Contract that could be used as a base contract for
 * ERC-20 token contracts supporting virtual balance.
 */
contract AbstractVirtualToken is AbstractToken {
  /**
   * Maximum number of real (i.e. non-virtual) tokens in circulation (2^255-1).
   */
  uint256 constant MAXIMUM_TOKENS_COUNT =
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Mask used to extract real balance of an account (2^255-1).
   */
  uint256 constant BALANCE_MASK =
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Mask used to extract &quot;materialized&quot; flag of an account (2^255).
   */
  uint256 constant MATERIALIZED_FLAG_MASK =
    0x8000000000000000000000000000000000000000000000000000000000000000;

  /**
   * Create new Abstract Virtual Token contract.
   */
  function AbstractVirtualToken () public AbstractToken () {
    // Do nothing
  }

  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public view returns (uint256 supply) {
    return tokensCount;
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public view returns (uint256 balance) {
    return safeAdd (
      accounts [_owner] &amp; BALANCE_MASK, getVirtualBalance (_owner));
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public returns (bool success) {
    if (_value &gt; balanceOf (msg.sender)) return false;
    else {
      materializeBalanceIfNeeded (msg.sender, _value);
      return AbstractToken.transfer (_to, _value);
    }
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    if (_value &gt; allowance (_from, msg.sender)) return false;
    if (_value &gt; balanceOf (_from)) return false;
    else {
      materializeBalanceIfNeeded (_from, _value);
      return AbstractToken.transferFrom (_from, _to, _value);
    }
  }

  /**
   * Get virtual balance of the owner of given address.
   *
   * @param _owner address to get virtual balance for the owner of
   * @return virtual balance of the owner of given address
   */
  function virtualBalanceOf (address _owner)
  internal view returns (uint256 _virtualBalance);

  /**
   * Calculate virtual balance of the owner of given address taking into account
   * materialized flag and total number of real tokens already in circulation.
   */
  function getVirtualBalance (address _owner)
  private view returns (uint256 _virtualBalance) {
    if (accounts [_owner] &amp; MATERIALIZED_FLAG_MASK != 0) return 0;
    else {
      _virtualBalance = virtualBalanceOf (_owner);
      uint256 maxVirtualBalance = safeSub (MAXIMUM_TOKENS_COUNT, tokensCount);
      if (_virtualBalance &gt; maxVirtualBalance)
        _virtualBalance = maxVirtualBalance;
    }
  }

  /**
   * Materialize virtual balance of the owner of given address if this will help
   * to transfer given number of tokens from it.
   *
   * @param _owner address to materialize virtual balance of
   * @param _value number of tokens to be transferred
   */
  function materializeBalanceIfNeeded (address _owner, uint256 _value) private {
    uint256 storedBalance = accounts [_owner];
    if (storedBalance &amp; MATERIALIZED_FLAG_MASK == 0) {
      // Virtual balance is not materialized yet
      if (_value &gt; storedBalance) {
        // Real balance is not enough
        uint256 virtualBalance = getVirtualBalance (_owner);
        require (safeSub (_value, storedBalance) &lt;= virtualBalance);
        accounts [_owner] = MATERIALIZED_FLAG_MASK |
          safeAdd (storedBalance, virtualBalance);
        tokensCount = safeAdd (tokensCount, virtualBalance);
      }
    }
  }

  /**
   * Number of real (i.e. non-virtual) tokens in circulation.
   */
  uint256 internal tokensCount;
}
/*
 * MediChain Promo Token Smart Contract.  Copyright &#169; 2018 by ABDK Consulting.
 * Author: Mikhail Vladimirov &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="670a0e0c0f060e0b49110b06030e0a0e15081127000a060e0b4904080a">[email&#160;protected]</a>&gt;
 */

/**
 * MediChain Promo Token Smart Contract.
 */
contract MediChainBonus30PToken is AbstractVirtualToken {
  /**
   * Number of virtual tokens to assign to the owners of addresses from given
   * address set.
   */
  uint256 private constant VIRTUAL_COUNT = 10e8;
  
   /**
   * Number of real tokens to assign to the contract owner.
   */
  uint256 private constant INITIAL_SUPPLY=3000000e8;

  /**
   * Create MediChainBonusToken smart contract with given address set.
   *
   * @param _addressSet address set to use
   */
  function MediChainBonus30PToken (AddressSet _addressSet)
  public AbstractVirtualToken () {
    owner = msg.sender;
	accounts[owner] = INITIAL_SUPPLY;
    addressSet = _addressSet;
    tokensCount = INITIAL_SUPPLY;
  }

  /**
   * Get name of this token.
   *
   * @return name of this token
   */
  function name () public pure returns (string) {
    return &quot;MediChain Bonus30Percent Token&quot;;
  }

  /**
   * Get symbol of this token.
   *
   * @return symbol of this token
   */
  function symbol () public pure returns (string) {
    return &quot;XMCU2&quot;;
  }

  /**
   * Get number of decimals for this token.
   *
   * @return number of decimals for this token
   */
  function decimals () public pure returns (uint8) {
    return 8;
  }

  /**
   * Notify owners about their virtual balances.
   *
   * @param _owners addresses of the owners to be notified
   */
  function massNotify (address [] _owners) public {
    require (msg.sender == owner);
    uint256 count = _owners.length;
    for (uint256 i = 0; i &lt; count; i++)
      Transfer (address (0), _owners [i], VIRTUAL_COUNT);
  }

  /**
   * Kill this smart contract.
   */
  function kill () public {
    require (msg.sender == owner);
    selfdestruct (owner);
  }

  /**
   * Change owner of the smart contract.
   *
   * @param _owner address of a new owner of the smart contract
   */
  function changeOwner (address _owner) public {
    require (msg.sender == owner);

    owner = _owner;
  }
  
   /**
   * Change address set of the smart contract.
   *
   * @param _addressSet address of a new address set of the smart contract
   */
  function changeAddressSet (AddressSet _addressSet) public {
    require (msg.sender == owner);

    addressSet = _addressSet;
  }

  /**
   * Get virtual balance of the owner of given address.
   *
   * @param _owner address to get virtual balance for the owner of
   * @return virtual balance of the owner of given address
   */
  function virtualBalanceOf (address _owner)
  internal view returns (uint256 _virtualBalance) {
    return addressSet.contains (_owner) ? VIRTUAL_COUNT : 0;
  }

  /**
   * Address of the owner of this smart contract.
   */
  address internal owner;

  /**
   * Address set of addresses that are eligible for initial balance.
   */
  AddressSet internal addressSet;
}