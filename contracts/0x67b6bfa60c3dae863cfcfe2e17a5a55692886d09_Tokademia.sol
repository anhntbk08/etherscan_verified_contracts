pragma solidity 0.4.19;

// Proyecto Tokademia - Fomentando la presencia de la Blockchain en Chile. 

contract Token {

    function totalSupply() constant returns (uint supply) {}
    function balanceOf(address _owner) constant returns (uint balance) {}
    function transfer(address _to, uint _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}
    function approve(address _spender, uint _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint _value) returns (bool) {
     
        if (balances[msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt;= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt;= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address =&gt; uint) balances;
    mapping (address =&gt; mapping (address =&gt; uint)) allowed;
    uint public totalSupply;
}

contract UnlimitedAllowanceToken is StandardToken {

    uint constant MAX_UINT = 2**256 - 1;
    
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] &gt;= _value
            &amp;&amp; allowance &gt;= _value
            &amp;&amp; balances[_to] + _value &gt;= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance &lt; MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract Tokademia is UnlimitedAllowanceToken {

    uint8 constant public decimals = 2;
    uint public totalSupply = 40**10;
    string constant public name = &quot;Academia Token&quot;;
    string constant public symbol = &quot;ACAD&quot;;

    function Tokademia() {
        balances[msg.sender] = totalSupply;
    }
}

// S&#237;guenos en t.me/Tokademia 
// Tokademia libera su responsabilidad por mal uso de este token.