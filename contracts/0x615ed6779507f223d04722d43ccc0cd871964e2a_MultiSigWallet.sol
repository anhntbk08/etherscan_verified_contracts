pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------------------------
// Gifto Token by Gifto Limited.
// An ERC20 standard
//
// author: Gifto Team
// Contact: <span class="__cf_email__" data-cfemail="4c282d383b24222b393529220c2b212d2520622f2321">[email&#160;protected]</span>

contract ERC20Interface {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // approve an address with _value amount of tokens
    function approve(address _spender, uint256 _value) public returns (bool success);

    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract Gifto is ERC20Interface {
    uint256 public constant decimals = 5;

    string public constant symbol = &quot;GTO&quot;;
    string public constant name = &quot;Gifto&quot;;

    bool public _selling = true;//initial selling
    uint256 public _totalSupply = 10 ** 14; // total supply is 10^14 unit, equivalent to 10^9 Gifto
    uint256 public _originalBuyPrice = 43 * 10**7; // original buy 1ETH = 4300 Gifto = 43 * 10**7 unit

    // Owner of this contract
    address public owner;
 
    // Balances Gifto for each account
    mapping(address =&gt; uint256) private balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address =&gt; mapping (address =&gt; uint256)) private allowed;

    // List of approved investors
    mapping(address =&gt; bool) private approvedInvestorList;
    
    // deposit
    mapping(address =&gt; uint256) private deposit;
    
    // icoPercent
    uint256 public _icoPercent = 10;
    
    // _icoSupply is the avalable unit. Initially, it is _totalSupply
    uint256 public _icoSupply = _totalSupply * _icoPercent / 100;
    
    // minimum buy 0.3 ETH
    uint256 public _minimumBuy = 3 * 10 ** 17;
    
    // maximum buy 25 ETH
    uint256 public _maximumBuy = 25 * 10 ** 18;

    // totalTokenSold
    uint256 public totalTokenSold = 0;
    
    // tradable
    bool public tradable = false;
    
    /**
     * Functions with this modifier can only be executed by the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Functions with this modifier check on sale status
     * Only allow sale if _selling is on
     */
    modifier onSale() {
        require(_selling);
        _;
    }
    
    /**
     * Functions with this modifier check the validity of address is investor
     */
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
    /**
     * Functions with this modifier check the validity of msg value
     * value must greater than equal minimumBuyPrice
     * total deposit must less than equal maximumBuyPrice
     */
    modifier validValue(){
        // require value &gt;= _minimumBuy AND total deposit of msg.sender &lt;= maximumBuyPrice
        require ( (msg.value &gt;= _minimumBuy) &amp;&amp;
                ( (deposit[msg.sender] + msg.value) &lt;= _maximumBuy) );
        _;
    }
    
    /**
     * 
     */
    modifier isTradable(){
        require(tradable == true || msg.sender == owner);
        _;
    }

    /// @dev Fallback function allows to buy ether.
    function()
        public
        payable {
        buyGifto();
    }
    
    /// @dev buy function allows to buy ether. for using optional data
    function buyGifto()
        public
        payable
        onSale
        validValue
        validInvestor {
        uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10**18;
        require(balances[owner] &gt;= requestedUnits);
        // prepare transfer data
        balances[owner] -= requestedUnits;
        balances[msg.sender] += requestedUnits;
        
        // increase total deposit amount
        deposit[msg.sender] += msg.value;
        
        // check total and auto turnOffSale
        totalTokenSold += requestedUnits;
        if (totalTokenSold &gt;= _icoSupply){
            _selling = false;
        }
        
        // submit transfer
        Transfer(owner, msg.sender, requestedUnits);
        owner.transfer(msg.value);
    }

    /// @dev Constructor
    function Gifto() 
        public {
        owner = msg.sender;
        setBuyPrice(_originalBuyPrice);
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
    /// @dev Gets totalSupply
    /// @return Total supply
    function totalSupply()
        public 
        constant 
        returns (uint256) {
        return _totalSupply;
    }
    
    /// @dev Enables sale 
    function turnOnSale() onlyOwner 
        public {
        _selling = true;
    }

    /// @dev Disables sale
    function turnOffSale() onlyOwner 
        public {
        _selling = false;
    }
    
    function turnOnTradable() 
        public
        onlyOwner{
        tradable = true;
    }
    
    /// @dev set new icoPercent
    /// @param newIcoPercent new value of icoPercent
    function setIcoPercent(uint256 newIcoPercent)
        public 
        onlyOwner {
        _icoPercent = newIcoPercent;
        _icoSupply = _totalSupply * _icoPercent / 100;
    }
    
    /// @dev set new _maximumBuy
    /// @param newMaximumBuy new value of _maximumBuy
    function setMaximumBuy(uint256 newMaximumBuy)
        public 
        onlyOwner {
        _maximumBuy = newMaximumBuy;
    }

    /// @dev Updates buy price (owner ONLY)
    /// @param newBuyPrice New buy price (in unit)
    function setBuyPrice(uint256 newBuyPrice) 
        onlyOwner 
        public {
        require(newBuyPrice&gt;0);
        _originalBuyPrice = newBuyPrice; // 3000 Gifto = 3000 00000 unit
        // control _maximumBuy_USD = 10,000 USD, Gifto price is 0.1USD
        // maximumBuy_Gifto = 100,000 Gifto = 100,000,00000 unit
        // 3000 Gifto = 1ETH =&gt; maximumETH = 100,000,00000 / _originalBuyPrice
        // 100,000,00000/3000 0000 ~ 33ETH =&gt; change to wei
        _maximumBuy = 10**18 * 10000000000 /_originalBuyPrice;
    }
        
    /// @dev Gets account&#39;s balance
    /// @param _addr Address of the account
    /// @return Account balance
    function balanceOf(address _addr) 
        public
        constant 
        returns (uint256) {
        return balances[_addr];
    }
    
    /// @dev check address is approved investor
    /// @param _addr address
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }
    
    /// @dev get ETH deposit
    /// @param _addr address get deposit
    /// @return amount deposit of an buyer
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
        return deposit[_addr];
}
    
    /// @dev Adds list of new investors to the investors list and approve all
    /// @param newInvestorList Array of new investors addresses to be added
    function addInvestorList(address[] newInvestorList)
        onlyOwner
        public {
        for (uint256 i = 0; i &lt; newInvestorList.length; i++){
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }

    /// @dev Removes list of investors from list
    /// @param investorList Array of addresses of investors to be removed
    function removeInvestorList(address[] investorList)
        onlyOwner
        public {
        for (uint256 i = 0; i &lt; investorList.length; i++){
            approvedInvestorList[investorList[i]] = false;
        }
    }
 
    /// @dev Transfers the balance from msg.sender to an account
    /// @param _to Recipient address
    /// @param _amount Transfered amount in unit
    /// @return Transfer status
    function transfer(address _to, uint256 _amount)
        public 
        isTradable
        returns (bool) {
        // if sender&#39;s balance has enough unit and amount &gt;= 0, 
        //      and the sum is not overflow,
        // then do transfer 
        if ( (balances[msg.sender] &gt;= _amount) &amp;&amp;
             (_amount &gt;= 0) &amp;&amp; 
             (balances[_to] + _amount &gt; balances[_to]) ) {  

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to &quot;deposit&quot; to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public
    isTradable
    returns (bool success) {
        if (balances[_from] &gt;= _amount
            &amp;&amp; allowed[_from][msg.sender] &gt;= _amount
            &amp;&amp; _amount &gt; 0
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) 
        public
        isTradable
        returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    // get allowance
    function allowance(address _owner, address _spender) 
        public
        constant 
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /// @dev Withdraws Ether in contract (Owner only)
    /// @return Status of withdrawal
    function withdraw() onlyOwner 
        public 
        returns (bool) {
        return owner.send(this.balance);
    }
}

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - &lt;<span class="__cf_email__" data-cfemail="4b383f2e2d2a25652c2e24392c2e0b282425382e2538323865252e3f">[email&#160;protected]</span>&gt;
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event CoinCreation(address coin);

    mapping (uint =&gt; Transaction) public transactions;
    mapping (uint =&gt; mapping (address =&gt; bool)) public confirmations;
    mapping (address =&gt; bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    bool flag = true;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            revert();
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount &gt; MAX_OWNER_COUNT
            || _required &gt; ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value &gt; 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i&lt;_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i&lt;owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required &gt; owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i&lt;owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i&lt;owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i&lt;owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i&lt;transactionCount; i++)
            if (   pending &amp;&amp; !transactions[i].executed
                || executed &amp;&amp; transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i&lt;owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i&lt;count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i&lt;transactionCount; i++)
            if (   pending &amp;&amp; !transactions[i].executed
                || executed &amp;&amp; transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i&lt;to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
    
    /// @dev Create new coin.
    function createCoin()
        external
        onlyWallet
    {
        require(flag == true);
        CoinCreation(new Gifto());
        flag = false;
    }
}