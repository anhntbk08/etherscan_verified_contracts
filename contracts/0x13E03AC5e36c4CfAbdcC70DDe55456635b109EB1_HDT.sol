pragma solidity ^0.4.18;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b &lt;= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a &gt;= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a &lt; b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a &gt;= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a &lt; b ? a : b;
    }

}
contract Ownable {
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
}
contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address =&gt; uint256) balances;
    uint256 public totalSupply;

    modifier onlyPayloadSize(uint256 size) {
        if(msg.data.length &lt; size + 4) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}
contract StandardToken is BasicToken, ERC20 {

    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        if ((_value != 0) &amp;&amp; (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
contract HDT is StandardToken, Ownable {

    string public constant name = &quot;Hard Token&quot;;
    string public constant symbol = &quot;HDT&quot;;
    uint256 public constant decimals = 8;

    function HDT() public {
        owner = msg.sender;
        totalSupply=100000000000000;
        balances[owner]=totalSupply;
    }

    function () public {
        revert();
    }
}