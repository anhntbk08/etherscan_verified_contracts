pragma solidity ^0.4.17;

contract PresaleToken {
    
    /// Fields:
    string public constant name = &quot;ShiftCash Presale Token&quot;;
    string public constant symbol = &quot;SCASH&quot;;
    uint public constant decimals = 18;
    uint public constant PRICE = 598;  // per 1 Ether

    //  price
    // Cap is 4000 ETH
    // 1 eth = 598;  presale SCASH tokens
    uint public constant TOKEN_SUPPLY_LIMIT = 2392000 * (1 ether / 1 wei);

    enum State{
        Init,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    State public currentState = State.Init;
    uint public totalSupply = 0; // amount of tokens already sold

    // Gathered funds can be withdrawn only to escrow&#39;s address.
    address public escrow = 0;

    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager = 0;

    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager = 0;

    mapping (address =&gt; uint256) private balance;
    mapping (address =&gt; bool) ownerAppended;
    address[] public owners;

    /// Modifiers:
    modifier onlyTokenManager()     { require(msg.sender == tokenManager); _; }
    modifier onlyCrowdsaleManager() { require(msg.sender == crowdsaleManager); _; }
    modifier onlyInState(State state){ require(state == currentState); _; }

    /// Events:
    event LogBurn(address indexed owner, uint value);
    event LogStateSwitch(State newState);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    /// Functions:
    /// @dev Constructor
    /// @param _tokenManager Token manager address.
    function PresaleToken(address _tokenManager, address _escrow) public {
        require(_tokenManager != 0);
        require(_escrow != 0);

        tokenManager = _tokenManager;
        escrow = _escrow;
    }

    function buyTokens(address _buyer) public payable onlyInState(State.Running) {
        require(msg.value != 0);
        uint newTokens = msg.value * PRICE;

        require(totalSupply + newTokens &lt;= TOKEN_SUPPLY_LIMIT);

        balance[_buyer] += newTokens;
        totalSupply += newTokens;
        
        if(!ownerAppended[_buyer]) {
            ownerAppended[_buyer] = true;
            owners.push(_buyer);
        }
        
        Transfer(msg.sender, _buyer, newTokens);

        if(this.balance &gt; 0) {
            require(escrow.send(this.balance));
        }

    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public onlyCrowdsaleManager onlyInState(State.Migrating) {
        uint tokens = balance[_owner];
        require(tokens != 0);

        balance[_owner] = 0;
        totalSupply -= tokens;

        LogBurn(_owner, tokens);

        // Automatically switch phase when migration is done.
        if(totalSupply == 0) {
            currentState = State.Migrated;
            LogStateSwitch(State.Migrated);
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
        return balance[_owner];
    }

    function setPresaleState(State _nextState) public onlyTokenManager {
        // Init -&gt; Running
        // Running -&gt; Paused
        // Running -&gt; Migrating
        // Paused -&gt; Running
        // Paused -&gt; Migrating
        // Migrating -&gt; Migrated
        bool canSwitchState
        =  (currentState == State.Init &amp;&amp; _nextState == State.Running)
        || (currentState == State.Running &amp;&amp; _nextState == State.Paused)
        // switch to migration phase only if crowdsale manager is set
        || ((currentState == State.Running || currentState == State.Paused)
        &amp;&amp; _nextState == State.Migrating
        &amp;&amp; crowdsaleManager != 0x0)
        || (currentState == State.Paused &amp;&amp; _nextState == State.Running)
        // switch to migrated only if everyting is migrated
        || (currentState == State.Migrating &amp;&amp; _nextState == State.Migrated
        &amp;&amp; totalSupply == 0);

        require(canSwitchState);

        currentState = _nextState;
        LogStateSwitch(_nextState);
    }

    /// Setters/getters
    function setTokenManager(address _mgr) public onlyTokenManager {
        tokenManager = _mgr;
    }

    function setCrowdsaleManager(address _mgr) public onlyTokenManager {
        // You can&#39;t change crowdsale contract when migration is in progress.
        require(currentState != State.Migrating);
        crowdsaleManager = _mgr;
    }

    function getTokenManager() constant returns(address) {
        return tokenManager;
    }

    function getCrowdsaleManager() constant returns(address) {
        return crowdsaleManager;
    }

    function getCurrentState() constant returns(State) {
        return currentState;
    }

    function getPrice() constant returns(uint) {
        return PRICE;
    }

    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balance[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }
    

    // Default fallback function
    function() payable {
        buyTokens(msg.sender);
    }
}