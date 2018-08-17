pragma solidity ^0.4.12;/* Need Price Token */contract ConfToken { address internal listenerAddr; address public owner; uint256 public initialIssuance; uint public totalSupply; uint256 public currentEthPrice; /* In USD */ uint256 public currentTokenPrice; /* In USD */ uint256 public ticketPrice; string public symbol; struct productAmount { bytes32 name; uint amnt; } mapping (address =&gt; mapping (address =&gt; uint256)) allowed; mapping (address =&gt; uint256) public balances; mapping (bytes32 =&gt; uint256) public productListing; /*(Product : Price)*/ mapping (address =&gt; productAmount[]) public productOwners; /* Address =&gt; (productName =&gt; amount) */ function ConfToken() { totalSupply = 10000000; initialIssuance = totalSupply; owner = msg.sender; currentEthPrice = 1; /* TODO: Oracle */ currentTokenPrice = 1; /* USD */ symbol = &quot;CONF&quot;; balances[owner] = 11000000; } /* Math Helpers */ function safeMul(uint a, uint b) constant internal returns (uint) { uint c = a * b; assert(a == 0 || c / a == b); return c; } function safeSub(uint a, uint b) constant internal returns (uint) { assert(b &lt;= a); return a - b; } function safeAdd(uint a, uint b) constant internal returns (uint) { uint c = a + b; assert(c&gt;=a &amp;&amp; c&gt;=b); return c; } function stringToUint(string s) constant returns (uint result) { bytes memory b = bytes(s); uint i; result = 0;  for (i = 0; i &lt; b.length; i++) { uint c = uint(b[i]); if (c &gt;= 48 &amp;&amp; c &lt;= 57) {  result = result * 10 + (c - 48); } } } /* Methods */ function balanceOf(address _addr) constant returns (uint balance){ return balances[_addr]; } function totalSupply() constant returns (uint totalSupply){ return totalSupply; } function setTokenPrice(uint128 _amount){ assert(msg.sender == owner); currentTokenPrice = _amount; } function setEthPrice(uint128 _amount){ assert(msg.sender == owner); currentEthPrice = _amount; } function seeEthPrice() constant returns (uint256){ return currentEthPrice; } function __getEthPrice(uint256 price){  /* Oracle Calls this function */  assert(msg.sender == owner);  currentEthPrice = price; } function createProduct(bytes32 name, uint128 price){ assert(msg.sender == owner); productListing[name] = price; } function checkProduct(bytes32 name) returns (uint productAmnt){ productAmount[] storage ownedProducts = productOwners[msg.sender]; for (uint i = 0; i &lt; ownedProducts.length; i++) { bytes32 prodName = ownedProducts[i].name; if (prodName == name){ return ownedProducts[i].amnt; } } } function purchaseProduct(bytes32 name,uint amnt){ assert(productListing[name] != 0); uint256 productsPrice = productListing[name] * amnt; assert(balances[msg.sender] &gt;= productsPrice); balances[msg.sender] = safeSub(balances[msg.sender], productsPrice); productOwners[msg.sender].push(productAmount(name,amnt)); } function buyToken() payable returns (uint256){ /* Need return Change Function */ assert(msg.value &gt; currentTokenPrice); assert(msg.value &gt; 0); uint256 oneEth = 1000000000000000000; /* calculate price for 1 wei */ uint conversionFactor = oneEth * 100; uint256 tokenAmount = ((msg.value * currentEthPrice)/(currentTokenPrice * conversionFactor))/10000000000000000; /* Needs decimals */ assert((tokenAmount != 0) || (tokenAmount &lt;= totalSupply)); totalSupply = safeSub(totalSupply,tokenAmount); if (balances[msg.sender] != 0) { balances[msg.sender] = safeAdd(balances[msg.sender], tokenAmount); }else{ balances[msg.sender] = tokenAmount; } return tokenAmount; } function transfer(address _to, uint256 _value) payable returns (bool success){ assert((_to != 0) &amp;&amp; (_value &gt; 0)); assert(balances[msg.sender] &gt;= _value);  assert(safeAdd(balances[_to], _value) &gt; balances[_to]); Transfer(msg.sender, _to, _value); balances[msg.sender] = safeSub(balances[msg.sender],_value); balances[_to] = safeAdd(balances[msg.sender], _value); return true; } function transferFrom(address _from, address _to, uint256 _value) returns (bool success){ assert(allowed[_from][msg.sender] &gt;= _value); assert(_value &gt; 0);  assert(balances[_to] + _value &gt; balances[_to]); balances[_from] = safeSub(balances[_from],_value); allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value); balances[_to] = safeAdd(balances[_to], _value); return true; } function approve(address _spender, uint _value) returns (bool success){ allowed[msg.sender][_spender] = _value; return true; } function allowance(address _owner, address _spender) constant returns (uint remaining){ return allowed[_owner][_spender]; } event Transfer(address indexed _from, address indexed _to, uint _value); event Approval (address indexed _owner, address indexed _spender, uint _value); function() { revert(); }}