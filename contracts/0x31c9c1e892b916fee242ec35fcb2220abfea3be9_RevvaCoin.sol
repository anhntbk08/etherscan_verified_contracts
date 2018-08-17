pragma solidity ^0.4.8;

/*
AvatarNetwork Copyright

https://avatarnetwork.io
*/

contract Owned {

    address owner;

    function Owned() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) onlyOwner {
        owner = newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender==owner) _;
    }
}

contract Token is Owned {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Err(uint256 _value);
}

contract ERC20Token is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (balances[msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
}

contract RevvaCoin is ERC20Token {

    bool public isTokenSale = true;
    uint256 public price;
    uint256 public limit;

    address walletOut = 0x5eeF56FF0eE166bd0E4C36e55dB04CD87CaA6e9A;

    function getWalletOut() constant returns (address _to) {
        return walletOut;
    }

    function () external payable  {
        if (isTokenSale == false) {
            throw;
        }

        uint256 tokenAmount = (msg.value  * 100000000) / price;

        if (balances[owner] &gt;= tokenAmount &amp;&amp; balances[msg.sender] + tokenAmount &gt; balances[msg.sender]) {
            if (balances[owner] - tokenAmount &lt; limit) {
                throw;
            }
            balances[owner] -= tokenAmount;
            balances[msg.sender] += tokenAmount;
            Transfer(owner, msg.sender, tokenAmount);
        } else {
            throw;
        }
    }

    function stopSale() onlyOwner {
        isTokenSale = false;
    }

    function startSale() onlyOwner {
        isTokenSale = true;
    }

    function setPrice(uint256 newPrice) onlyOwner {
        price = newPrice;
    }

    function setLimit(uint256 newLimit) onlyOwner {
        limit = newLimit;
    }

    function setWallet(address _to) onlyOwner {
        walletOut = _to;
    }

    function sendFund() onlyOwner {
        walletOut.send(this.balance);
    }

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = &#39;1.0&#39;;

    function RevvaCoin() {
        totalSupply = 10000000 * 100000000;
        balances[msg.sender] = totalSupply;
        name = &#39;RevvaCoin&#39;;
        decimals = 8;
        symbol = &#39;REVVA&#39;;
        price = 12500000000000000;
        limit = totalSupply - 100000000000000;
    }


    /* Добавляет на счет токенов */
    function add(uint256 _value) onlyOwner returns (bool success)
    {
        if (balances[msg.sender] + _value &lt;= balances[msg.sender]) {
            return false;
        }
        totalSupply += _value;
        balances[msg.sender] += _value;

        return true;
    }

    /* Уничтожает токены на счете владельца контракта */
    function burn(uint256 _value) onlyOwner  returns (bool success)
    {
        if (balances[msg.sender] &lt; _value) {
            return false;
        }
        totalSupply -= _value;
        balances[msg.sender] -= _value;
        return true;
    }
}