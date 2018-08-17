pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Xi Ma La Ya contract
//
// Deployed to : msg.sender
// Symbol      : XMLY
// Name        : XiMaLaYa
// Total supply: 100000000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c &gt;= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b &lt;= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b &gt; 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = 0x5B807E379170d42f3B099C01A5399a2e1e58963B;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract XMLYToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address =&gt; uint) balances;
    mapping(address =&gt; mapping(address =&gt; uint)) allowed;
    mapping(address =&gt; bool) freezed;
    mapping(address =&gt; uint) freezeAmount;
    mapping(address =&gt; uint) unlockTime;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function XMLYToken() public {
        symbol = &quot;XMLY&quot;;
        name = &quot;XiMaLaYa&quot;;
        decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        balances[0x5B807E379170d42f3B099C01A5399a2e1e58963B] = _totalSupply;
        Transfer(address(0), 0x5B807E379170d42f3B099C01A5399a2e1e58963B, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        if(freezed[msg.sender] == false){
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            Transfer(msg.sender, to, tokens);
        } else {
            if(balances[msg.sender] &gt; freezeAmount[msg.sender]) {
                require(tokens &lt;= safeSub(balances[msg.sender], freezeAmount[msg.sender]));
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);
                Transfer(msg.sender, to, tokens);
            }
        }
            
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        require(freezed[msg.sender] != true);
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Burn Tokens
    // ------------------------------------------------------------------------
    function burn(uint amount) public onlyOwner {
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function freeze(address user, uint amount, uint period) public onlyOwner {
        require(balances[user] &gt;= amount);
        freezed[user] = true;
        unlockTime[user] = uint(now) + period;
        freezeAmount[user] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function unFreeze() public {
        require(freezed[msg.sender] == true);
        require(unlockTime[msg.sender] &lt; uint(now));
        freezed[msg.sender] = false;
        freezeAmount[msg.sender] = 0;
    }
    
    function ifFreeze(address user) public view returns (
        bool check, 
        uint amount, 
        uint timeLeft
    ) {
        check = freezed[user];
        amount = freezeAmount[user];
        timeLeft = unlockTime[user] - uint(now);
    }

    // ------------------------------------------------------------------------
    // Accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}