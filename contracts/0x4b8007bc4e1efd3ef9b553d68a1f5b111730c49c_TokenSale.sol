pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  function Pausable() {}

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract TokenSale is Pausable {

  using SafeMath for uint256;

  ProofTokenInterface public proofToken;
  uint256 public weiRaised;
  uint256 public rate;
  uint256 public contributors;
  uint256 public decimalsMultiplier;
  uint256 public startBlock;
  uint256 public endBlock;
  uint256 public remainingTokens;
  uint256 public allocatedTokens;
  bool public finalized;

  uint256 public constant BASE_PRICE_IN_WEI = 88000000000000000;

  uint256 public constant TOTAL_TOKENS = 2 * 1181031 * (10 ** 18);
  uint256 public constant PUBLIC_TOKENS = 1181031 * (10 ** 18);
  uint256 public constant TOTAL_PRESALE_TOKENS = 112386712924725508802400;
  uint256 public constant TOKENS_ALLOCATED_TO_PROOF = 1181031 * (10 ** 18);

  address public constant PROOF_MULTISIG = 0x11e3de1bdA2650fa6BC74e7Cea6A39559E59b103;
  address public constant PROOF_TOKEN_WALLET = 0x11e3de1bdA2650fa6BC74e7Cea6A39559E59b103;

  uint256 public tokenCap = PUBLIC_TOKENS - TOTAL_PRESALE_TOKENS;
  uint256 public cap = tokenCap / (10 ** 18);
  uint256 public weiCap = cap * BASE_PRICE_IN_WEI;

  uint256 public firstCheckpointPrice = (BASE_PRICE_IN_WEI * 85) / 100;
  uint256 public secondCheckpointPrice = (BASE_PRICE_IN_WEI * 90) / 100;
  uint256 public thirdCheckpointPrice = (BASE_PRICE_IN_WEI * 95) / 100;

  uint256 public firstCheckpoint = (weiCap * 5) / 100;
  uint256 public secondCheckpoint = (weiCap * 10) / 100;
  uint256 public thirdCheckpoint = (weiCap * 20) / 100;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event NewClonedToken(address indexed _cloneToken);
  event OnTransfer(address _from, address _to, uint _amount);
  event OnApprove(address _owner, address _spender, uint _amount);
  event LogInt(string _name, uint256 _value);
  event Finalized();

  function TokenSale(
    address _tokenAddress,
    uint256 _startBlock,
    uint256 _endBlock) {
    require(_tokenAddress != 0x0);
    require(_startBlock &gt; 0);
    require(_endBlock &gt; _startBlock);

    startBlock = _startBlock;
    endBlock = _endBlock;
    proofToken = ProofTokenInterface(_tokenAddress);

    decimalsMultiplier = (10 ** 18);
  }


  /**
   * High level token purchase function
   */
  function() payable {
    buyTokens(msg.sender);
  }

  /**
   * Low level token purchase function
   * @param beneficiary will receive the tokens.
   */
  function buyTokens(address beneficiary) payable whenNotPaused whenNotFinalized {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 priceInWei = getPriceInWei();
    uint256 tokens = weiAmount.mul(decimalsMultiplier).div(priceInWei);

    weiRaised = weiRaised.add(weiAmount);
    contributors = contributors.add(1);
    proofToken.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }


  /**
   * Get the price in wei for current premium
   * @return price
   */
  function getPriceInWei() public returns (uint256) {

    uint256 price;

    if (weiRaised &lt; firstCheckpoint) {
      price = firstCheckpointPrice;
    } else if (weiRaised &lt; secondCheckpoint) {
      price = secondCheckpointPrice;
    } else if (weiRaised &lt; thirdCheckpoint) {
      price = thirdCheckpointPrice;
    } else {
      price = BASE_PRICE_IN_WEI;
    }

    return price;
  }

  /**
  * Forwards funds to the tokensale wallet
  */
  function forwardFunds() internal {
    PROOF_MULTISIG.transfer(msg.value);
  }


  /**
  * Validates the purchase (period, minimum amount, within cap)
  * @return {bool} valid
  */
  function validPurchase() internal returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current &gt;= startBlock &amp;&amp; current &lt;= endBlock;
    uint256 weiAmount = weiRaised.add(msg.value);
    bool nonZeroPurchase = msg.value != 0;
    bool withinCap = cap.mul(BASE_PRICE_IN_WEI) &gt;= weiAmount;

    return withinCap &amp;&amp; nonZeroPurchase &amp;&amp; withinPeriod;
  }

  /**
  * Returns the total Proof token supply
  * @return total supply {uint256}
  */
  function totalSupply() public constant returns (uint256) {
    return proofToken.totalSupply();
  }

  /**
  * Returns token holder Proof Token balance
  * @param _owner {address}
  * @return token balance {uint256}
  */
  function balanceOf(address _owner) public constant returns (uint256) {
    return proofToken.balanceOf(_owner);
  }

  //controller interface

  // function proxyPayment(address _owner) payable public {
  //   revert();
  // }

  /**
  * Controller Interface transfer callback method
  * @param _from {address}
  * @param _to {address}
  * @param _amount {number}
  */
  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    OnTransfer(_from, _to, _amount);
    return true;
  }

  /**
  * Controller Interface transfer callback method
  * @param _owner {address}
  * @param _spender {address}
  * @param _amount {number}
   */
  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    OnApprove(_owner, _spender, _amount);
    return true;
  }

  /**
  * Change the Proof Token controller
  * @param _newController {address}
  */
  function changeController(address _newController) public onlyOwner {
    proofToken.transferControl(_newController);
  }

  /**
  * Allocates Proof tokens to the given Proof Token wallet
  * @param _tokens {uint256}
  */
  function allocateProofTokens(uint256 _tokens) public onlyOwner whenNotFinalized {
    proofToken.mint(PROOF_TOKEN_WALLET, _tokens);
  }

  /**
  * Finalize the token sale (can only be called by owner)
  */
  function finalize() onlyOwner {
    require(paused);

    proofToken.finishMinting();
    Finalized();

    finalized = true;
  }

  modifier whenNotFinalized() {
    require(!paused);
    _;
  }

}

contract Controllable {
  address public controller;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  function Controllable() {
    controller = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newController The address to transfer ownership to.
   */
  function transferControl(address newController) onlyController {
    if (newController != address(0)) {
      controller = newController;
    }
  }

}

contract ProofTokenInterface is Controllable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() constant returns (uint);
  function totalSupplyAt(uint _blockNumber) constant returns(uint);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function balanceOfAt(address _owner, uint _blockNumber) constant returns (uint);
  function transfer(address _to, uint256 _amount) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);
  function doTransfer(address _from, address _to, uint _amount) internal returns(bool);
  function approve(address _spender, uint256 _amount) returns (bool success);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  function mint(address _owner, uint _amount) returns (bool);
  function importPresaleBalances(address[] _addresses, uint256[] _balances, address _presaleAddress) returns (bool);
  function lockPresaleBalances() returns (bool);
  function finishMinting() returns (bool);
  function enableTransfers(bool _transfersEnabled);
  function createCloneToken(uint _snapshotBlock, string _cloneTokenName, string _cloneTokenSymbol) returns (address);

}