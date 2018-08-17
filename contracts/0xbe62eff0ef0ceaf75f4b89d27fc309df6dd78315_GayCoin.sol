pragma solidity ^0.4.19;


contract GayCoin {
    address public owner; // Token owner address
    mapping (address =&gt; uint256) public balances; // balanceOf
    // mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    string public standard = &#39;Gay Coin Standart&#39;;
    string public constant name = &quot;GayCoin&quot;;
    string public constant symbol = &quot;GAY&quot;;
    uint   public constant decimals = 18;
    uint   public constant totalSupply = 21000000 * 1000000000000000000;
    
    uint   internal tokenPrice = 500000000000000;
    
    bool   public buyAllowed = false;
    
    bool   public transferBlocked = true;

    //
    // Events
    // This generates a publics event on the blockchain that will notify clients
    
    event Sent(address from, address to, uint amount);
    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //
    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyOwnerIfBlocked() {
        if(transferBlocked) {
            require(msg.sender == owner);   
        }
        _;
    }


    //
    // Functions
    // 

    // Constructor
    function GayCoin() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    // fallback function
    function() public payable {
        require(buyAllowed);
        require(msg.value &gt;= 1);
        require(msg.sender != owner);
        buyTokens(msg.sender);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b &lt;= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c&gt;=a &amp;&amp; c&gt;=b);
        return c;
    }


    // Payable function for buy coins from token owner
    function buyTokens(address _buyer) public payable
    {
        require(buyAllowed);
        require(msg.value &gt;= tokenPrice);
        require(_buyer != owner);
        
        uint256 wei_value = msg.value;

        uint256 tokens = wei_value / tokenPrice;
        tokens = tokens;

        balances[owner] = safeSub(balances[owner], tokens);
        balances[_buyer] = safeAdd(balances[_buyer], tokens);

        owner.transfer(this.balance);
        
        Buy(_buyer, msg.value, tokens);
        
    }


    function setTokenPrice(uint _newPrice) public
        onlyOwner
        returns (bool success)
    {
        tokenPrice = _newPrice;
        return true;
    }
    

    function getTokenPrice() public view
        returns (uint price)
    {
        return tokenPrice;
    }
    
    
    function setBuyAllowed(bool _allowed) public
        onlyOwner
    {
        buyAllowed = _allowed;
    }
    
    function setTransferBlocked(bool _blocked) public
        onlyOwner
    {
        transferBlocked = _blocked;
    }

 
    function withdrawEther(address _to) public 
        onlyOwner
    {
        _to.transfer(this.balance);
    }


    /**
     * ERC 20 token functions
     *
     * https://github.com/ethereum/EIPs/issues/20
     */
     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public
        onlyOwnerIfBlocked
        returns (bool success) 
    {
        if (balances[msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


    function transferFrom(address _from, address _to, uint256 _value) public
        onlyOwnerIfBlocked
        returns (bool success)
    {
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }


    function approve(address _spender, uint256 _value) public
        onlyOwnerIfBlocked
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public
        onlyOwnerIfBlocked
        constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

    
}