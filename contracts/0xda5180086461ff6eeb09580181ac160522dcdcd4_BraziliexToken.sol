pragma solidity ^0.4.11;
/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20

/// @title Abstract token contract - Functions to be implemented by token contracts.
/// @author braziliex dev team - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9afeffecdaf8e8fbe0f3f6f3ffe2b4f9f5f7">[email&#160;protected]</a>&gt;
contract Token {
    uint256 public totalSupply;
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract StandardToken is Token {

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
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

}


contract BraziliexToken is StandardToken {

    string constant public name = &quot;BraziliexToken&quot;;
    string constant public symbol = &quot;BRZX&quot;;
    uint8 constant public decimals = 8;


    function () {
        //if ether is sent to this address, send it back.
        throw;
    }


    function BraziliexToken() {
        balances[msg.sender] = 2100000000000000;
        totalSupply = 2100000000000000; // 21M
    }
}