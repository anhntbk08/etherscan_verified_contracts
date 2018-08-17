pragma solidity ^0.4.11;

/*
* LOK &#39;LookRev Token&#39; crowdfunding contract
*
* Refer to https://lookrev.com/ for further information.
* 
* Developer: LookRev (TM) 2017.
*
* Audited by BokkyPooBah / Bok Consulting Pty Ltd 2017.
* 
* The MIT License.
*
*/

/*
 * ERC20 Token Standard
 * https://github.com/ethereum/EIPs/issues/20
 *
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) constant returns (uint balance);
  function allowance(address _owner, address _spender) constant returns (uint remaining);

  function transfer(address _to, uint _value) returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) returns (bool ok);
  function approve(address _spender, uint _value) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c &gt;= a &amp;&amp; c &gt;= b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b &lt;= a);
    uint c = a - b;
    assert(c &lt;= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  address public newOwner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner {
    if (_newOwner != address(0)) {
      newOwner = _newOwner;
    }
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  event OwnershipTransferred(address indexed _from, address indexed _to);
}

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by InvestSeed
 */
contract StandardToken is ERC20, Ownable, SafeMath {

    mapping (address =&gt; uint) balances;
    mapping (address =&gt; mapping (address =&gt; uint)) allowed;

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _amount) returns (bool success) {
        if (balances[msg.sender] &gt;= _amount
            &amp;&amp; _amount &gt; 0
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]) {
            balances[msg.sender] = safeSub(balances[msg.sender],_amount);
            balances[_to] = safeAdd(balances[_to],_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
        if (balances[_from] &gt;= _amount
            &amp;&amp; allowed[_from][msg.sender] &gt;= _amount
            &amp;&amp; _amount &gt; 0
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]) {
            balances[_from] = safeSub(balances[_from],_amount);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_amount);
            balances[_to] = safeAdd(balances[_to],_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) &amp;&amp; (allowed[msg.sender][_spender] != 0)) {
           return false;
        }
        if (balances[msg.sender] &lt; _value) {
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint remaining) {
       return allowed[_owner][_spender];
     }
}

/**
 * LookRev token initial offering.
 *
 * Token supply is created in the token contract creation and allocated to owner.
 *
 */
contract LookRevToken is StandardToken {

    /*
    *  Token meta data
    */
    string public constant name = &quot;LookRev&quot;;
    string public constant symbol = &quot;LOK&quot;;
    uint8 public constant decimals = 18;
    string public VERSION = &#39;LOK1.0&#39;;
    bool public finalised = false;
    
    address public wallet;

    mapping(address =&gt; bool) public kycRequired;

    // Start - Wednesday, August 16, 2017 10:00:00 AM GMT-07:00 DST
    // End - Saturday, September 16, 2017 10:00:00 AM GMT-07:00 DST
    uint public constant START_DATE = 1502902800;
    uint public constant END_DATE = 1505581200;

    uint public constant DECIMALSFACTOR = 10**uint(decimals);
    uint public constant TOKENS_SOFT_CAP =   10000000 * DECIMALSFACTOR;
    uint public constant TOKENS_HARD_CAP = 2000000000 * DECIMALSFACTOR;
    uint public constant TOKENS_TOTAL =    4000000000 * DECIMALSFACTOR;
    uint public initialSupply = 10000000 * DECIMALSFACTOR;

    // 1 KETHER = 2,400,000 tokens
    // 1 ETH = 2,400 tokens
    // Presale 20% discount 1 ETH = 3,000 tokens
    // Presale 10% discount 1 ETH = 2,667 tokens
    uint public tokensPerKEther = 3000000;
    uint public CONTRIBUTIONS_MIN = 0 ether;
    uint public CONTRIBUTIONS_MAX = 0 ether;
    uint public constant KYC_THRESHOLD = 10000 * DECIMALSFACTOR;

    function LookRevToken() {
      owner = msg.sender;
      wallet = owner;
      totalSupply = initialSupply;
      balances[owner] = totalSupply;
    }

   // LookRev can change the crowdsale wallet address
   function setWallet(address _wallet) onlyOwner {
        wallet = _wallet;
        WalletUpdated(wallet);
    }
    event WalletUpdated(address newWallet);

    // Can only be set before the start of the crowdsale
    // Owner can change the rate before the crowdsale starts
    function setTokensPerKEther(uint _tokensPerKEther) onlyOwner {
        require(now &lt; START_DATE);
        require(_tokensPerKEther &gt; 0);
        tokensPerKEther = _tokensPerKEther;
        TokensPerKEtherUpdated(tokensPerKEther);
    }
    event TokensPerKEtherUpdated(uint tokensPerKEther);

    // Accept ethers to buy tokens during the crowdsale
    function () payable {
        proxyPayment(msg.sender);
    }

    // Accept ethers and exchanges to purchase tokens on behalf of user
    // msg.value (in units of wei)
    function proxyPayment(address participant) payable {

        require(!finalised);

        require(now &lt;= END_DATE);

        require(msg.value &gt; CONTRIBUTIONS_MIN);
        require(CONTRIBUTIONS_MAX == 0 || msg.value &lt; CONTRIBUTIONS_MAX);

         // Calculate number of tokens for contributed ETH
         // `18` is the ETH decimals
         // `- decimals` is the token decimals
         uint tokens = msg.value * tokensPerKEther / 10**uint(18 - decimals + 3);

         // Check if the hard cap will be exceeded
         require(totalSupply + tokens &lt;= TOKENS_HARD_CAP);

         // Add tokens purchased to account&#39;s balance and total supply
         balances[participant] = safeAdd(balances[participant],tokens);
         totalSupply = safeAdd(totalSupply,tokens);

         // Log the tokens purchased 
         Transfer(0x0, participant, tokens);
         // - buyer = participant
         // - ethers = msg.value
         // - participantTokenBalance = balances[participant]
         // - tokens = tokens
         // - newTotalSupply = totalSupply
         // - tokensPerKEther = tokensPerKEther
         TokensBought(participant, msg.value, balances[participant], tokens,
              totalSupply, tokensPerKEther);

         if (msg.value &gt; KYC_THRESHOLD) {
             // KYC verification required before participant can transfer the tokens
             kycRequired[participant] = true;
         }

         // Transfer the contributed ethers to the crowdsale wallet
         // throw is deprecated starting from Ethereum v0.9.0
         wallet.transfer(msg.value);
    }

    event TokensBought(address indexed buyer, uint ethers, 
        uint participantTokenBalance, uint tokens, uint newTotalSupply, 
        uint tokensPerKEther);

    function finalise() onlyOwner {
        // Can only finalise if raised &gt; soft cap or after the end date
        require(totalSupply &gt;= TOKENS_SOFT_CAP || now &gt; END_DATE);

        require(!finalised);

        finalised = true;
    }

   function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now &lt; START_DATE);
        require(balance &gt; 0);
        balances[participant] = safeAdd(balances[participant],balance);
        totalSupply = safeAdd(totalSupply,balance);
        Transfer(0x0, participant, balance);
        PrecommitmentAdded(participant, balance);
    }
    event PrecommitmentAdded(address indexed participant, uint balance);

    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends
        // Allow awarding team members before, during and after crowdsale
        require(finalised || msg.sender == owner);
        require(!kycRequired[msg.sender]);
        return super.transfer(_to, _amount);
    }

   function transferFrom(address _from, address _to, uint _amount) returns (bool success)
    {
        // Cannot transfer before crowdsale ends
        require(finalised);
        require(!kycRequired[_from]);
        return super.transferFrom(_from, _to, _amount);
    }

    function kycVerify(address participant, bool _required) onlyOwner {
        kycRequired[participant] = _required;
        KycVerified(participant, kycRequired[participant]);
    }
    event KycVerified(address indexed participant, bool required);

    // Any account can burn _from&#39;s tokens as long as the _from account has
    // approved the _amount to be burnt using approve(0x0, _amount)
    function burnFrom(address _from, uint _amount) returns (bool success) {
        require(totalSupply &gt;= _amount);

        if (balances[_from] &gt;= _amount
            &amp;&amp; allowed[_from][0x0] &gt;= _amount
            &amp;&amp; _amount &gt; 0
            &amp;&amp; balances[0x0] + _amount &gt; balances[0x0]
        ) {
            balances[_from] = safeSub(balances[_from],_amount);
            balances[0x0] = safeAdd(balances[0x0],_amount);
            allowed[_from][0x0] = safeSub(allowed[_from][0x0],_amount);
            totalSupply = safeSub(totalSupply,_amount);
            Transfer(_from, 0x0, _amount);
            return true;
        } else {
            return false;
        }
    }

    // LookRev can transfer out any accidentally sent ERC20 tokens
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success) 
    {
        return ERC20(tokenAddress).transfer(owner, amount);
    }
}