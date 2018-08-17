pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
// Integrative Wallet Token Crowdsale
// Iwtoken.com
// Taking ideas from @BokkyPooBah 
// Developer from @Adatum
// ----------------------------------------------------------------------------

/* Integrative Wallet Token */
/* Integrative Wallet Token */

// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c &gt;= a &amp;&amp; c &gt;= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) internal returns (uint) {
        assert(b &lt;= a);
        return a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Token is Owned {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Total Supply
    // ------------------------------------------------------------------------
    uint256 _totalSupply = 100000000;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address =&gt; uint256) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address =&gt; mapping (address =&gt; uint256)) allowed;

    // ------------------------------------------------------------------------
    // Get the total token supply
    // ------------------------------------------------------------------------
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] &gt;= _amount                // User has balance
            &amp;&amp; _amount &gt; 0                                 // Non-zero transfer
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]     // Overflow check
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount. If this function is called again it overwrites the
    // current allowance with _value.
    // ------------------------------------------------------------------------
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to the spender&#39;s account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] &gt;= _amount                  // From a/c has balance
            &amp;&amp; allowed[_from][msg.sender] &gt;= _amount    // Transfer approved
            &amp;&amp; _amount &gt; 0                              // Non-zero transfer
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]  // Overflow check
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract IntegrativeWalletToken is ERC20Token {

    // ------------------------------------------------------------------------
    // Token information
    // ------------------------------------------------------------------------
    string public constant symbol = &quot;IWT&quot;;
    string public constant name = &quot;Integrative Wallet&quot;;
    uint8 public constant decimals = 18;

    // Do not use `now` here
    uint256 public STARTDATE;
    uint256 public ENDDATE;

    // @ 12.500.000 USD / 261.1470 ETH/USD or 50.000 ETH 
	// Total CAP USD required 12.5 / 13 M Approximate  
    uint256 public CAP;

    // Cannot have a constant address here - Solidity bug
    // https://github.com/ethereum/solidity/issues/2441
    address public multisig;

    function IntegrativeWalletToken(uint256 _start, uint256 _end, uint256 _cap, address _multisig) {
        STARTDATE = _start;
        ENDDATE   = _end;
        CAP       = _cap;
        multisig  = _multisig;
    }

    // &gt; new Date(&quot;2017-06-29T13:00:00&quot;).getTime()/1000
    // 1498741200

    uint256 public totalEthers;

    // ------------------------------------------------------------------------
    // Tokens per ETH
    // Day  1    : 1,200 IWT = 1 Ether
    // Days 2–14 : 1,000 IWT = 1 Ether
    // Days 15–17: 800 IWT = 1 Ether
    // Days 18–27: 600 IWT = 1 Ether
    // ------------------------------------------------------------------------
	
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at &lt; STARTDATE) {
            return 0;
        } else if (at &lt; (STARTDATE + 1 days)) {
            return 1200;
        } else if (at &lt; (STARTDATE + 15 days)) {
            return 1000;
        } else if (at &lt; (STARTDATE + 18 days)) {
            return 800;
        } else if (at &lt; (STARTDATE + 24 days)) {
            return 600;
        } else if (at &lt;= ENDDATE) {
            return 600;
        } else {
            return 0;
        }
    }


    // ------------------------------------------------------------------------
    // Buy tokens from the contract
    // ------------------------------------------------------------------------
    function () payable {
        proxyPayment(msg.sender);
    }


    // ------------------------------------------------------------------------
    // Exchanges can buy on behalf of participant
    // ------------------------------------------------------------------------
    function proxyPayment(address participant) payable {
        // No contributions before the start of the crowdsale
        require(now &gt;= STARTDATE);
        // No contributions after the end of the crowdsale
        require(now &lt;= ENDDATE);
        // No 0 contributions
        require(msg.value &gt; 0);

        // Add ETH raised to total
        totalEthers = totalEthers.add(msg.value);
        // Cannot exceed cap
        require(totalEthers &lt;= CAP);

        // What is the BET to ETH rate
        uint256 _buyPrice = buyPrice();

        // Calculate #BET - this is safe as _buyPrice is known
        // and msg.value is restricted to valid values
        uint tokens = msg.value * _buyPrice;

        // Check tokens &gt; 0
        require(tokens &gt; 0);
        // Compute tokens for foundation &amp; bounties 55%
        // Number of tokens restricted so maths is safe
        uint multisigTokens = tokens * 55 / 100;

        // Add to total supply
        //_totalSupply = _totalSupply.add(tokens);
        //_totalSupply = _totalSupply.add(multisigTokens);
        // Not used -&gt; total supply on 100.000.000
		
        // Add to balances
        balances[participant] = balances[participant].add(tokens);
        balances[multisig] = balances[multisig].add(multisigTokens);

        // Log events
        TokensBought(participant, msg.value, totalEthers, tokens,
            multisigTokens, _totalSupply, _buyPrice);
        Transfer(0x0, participant, tokens);
        Transfer(0x0, multisig, multisigTokens);

        // Move the funds to a safe wallet
        multisig.transfer(msg.value);
    }
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, uint256 multisigTokens, 
        uint256 newTotalSupply, uint256 buyPrice);


    // ------------------------------------------------------------------------
    // Owner to add precommitment funding token balance before the crowdsale
    // commences
    // ------------------------------------------------------------------------
    function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now &lt; STARTDATE);
        require(balance &gt; 0);
        balances[participant] = balances[participant].add(balance);
        _totalSupply = _totalSupply.add(balance);
        Transfer(0x0, participant, balance);
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account, with a
    // check that the crowdsale is finalised
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) returns (bool success) {
        // Cannot transfer before crowdsale ends or cap reached
        require(now &gt; ENDDATE || totalEthers == CAP);
        // Standard transfer
        return super.transfer(_to, _amount);
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account, with a check that the crowdsale is
    // finalised
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
        // Cannot transfer before crowdsale ends or cap reached
        require(now &gt; ENDDATE || totalEthers == CAP);
        // Standard transferFrom
        return super.transferFrom(_from, _to, _amount);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}