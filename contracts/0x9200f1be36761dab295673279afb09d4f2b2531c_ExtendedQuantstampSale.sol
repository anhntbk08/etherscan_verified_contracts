pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract QuantstampSale is Pausable {

    using SafeMath for uint256;

    // The beneficiary is the future recipient of the funds
    address public beneficiary;

    // The crowdsale has a funding goal, cap, deadline, and minimum contribution
    uint public fundingCap;
    uint public minContribution;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

    // Whitelist data
    mapping(address =&gt; bool) public registry;

    // For each user, specifies the cap (in wei) that can be contributed for each tier
    // Tiers are filled in the order 3, 2, 1, 4
    mapping(address =&gt; uint256) public cap1;        // 100% bonus
    mapping(address =&gt; uint256) public cap2;        // 40% bonus
    mapping(address =&gt; uint256) public cap3;        // 20% bonus
    mapping(address =&gt; uint256) public cap4;        // 0% bonus

    // Stores the amount contributed for each tier for a given address
    mapping(address =&gt; uint256) public contributed1;
    mapping(address =&gt; uint256) public contributed2;
    mapping(address =&gt; uint256) public contributed3;
    mapping(address =&gt; uint256) public contributed4;


    // Conversion rate by tier (QSP : ETHER)
    uint public rate1 = 10000;
    uint public rate2 = 7000;
    uint public rate3 = 6000;
    uint public rate4 = 5000;

    // Time period of sale (UNIX timestamps)
    uint public startTime;
    uint public endTime;

    // Keeps track of the amount of wei raised
    uint public amountRaised;

    // prevent certain functions from being recursively called
    bool private rentrancy_lock = false;

    // The token being sold
    // QuantstampToken public tokenReward;

    // A map that tracks the amount of wei contributed by address
    mapping(address =&gt; uint256) public balanceOf;

    // A map that tracks the amount of QSP tokens that should be allocated to each address
    mapping(address =&gt; uint256) public tokenBalanceOf;


    // Events
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event RegistrationStatusChanged(address target, bool isRegistered, uint c1, uint c2, uint c3, uint c4);


    // Modifiers
    modifier beforeDeadline()   { require (currentTime() &lt; endTime); _; }
    // modifier afterDeadline()    { require (currentTime() &gt;= endTime); _; } no longer used without fundingGoal
    modifier afterStartTime()    { require (currentTime() &gt;= startTime); _; }

    modifier saleNotClosed()    { require (!saleClosed); _; }

    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

    /**
     * Constructor for a crowdsale of QuantstampToken tokens.
     *
     * @param ifSuccessfulSendTo            the beneficiary of the fund
     * @param fundingCapInEthers            the cap (maximum) size of the fund
     * @param minimumContributionInWei      minimum contribution (in wei)
     * @param start                         the start time (UNIX timestamp)
     * @param durationInMinutes             the duration of the crowdsale in minutes
     */
    function QuantstampSale(
        address ifSuccessfulSendTo,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint durationInMinutes
        // address addressOfTokenUsedAsReward
    ) {
        require(ifSuccessfulSendTo != address(0) &amp;&amp; ifSuccessfulSendTo != address(this));
        //require(addressOfTokenUsedAsReward != address(0) &amp;&amp; addressOfTokenUsedAsReward != address(this));
        require(durationInMinutes &gt; 0);
        beneficiary = ifSuccessfulSendTo;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        endTime = start + (durationInMinutes * 1 minutes);
        // tokenReward = QuantstampToken(addressOfTokenUsedAsReward);
    }

    /**
     * This function is called whenever Ether is sent to the
     * smart contract. It can only be executed when the crowdsale is
     * not paused, not closed, and before the deadline has been reached.
     *
     * This function will update state variables for whether or not the
     * funding goal or cap have been reached. It also ensures that the
     * tokens are transferred to the sender, and that the correct
     * number of tokens are sent according to the current rate.
     */
    function () payable {
        buy();
    }

    function buy ()
        payable public
        whenNotPaused
        beforeDeadline
        afterStartTime
        saleNotClosed
        nonReentrant
    {
        require(msg.value &gt;= minContribution);
        uint amount = msg.value;

        // ensure that the user adheres to whitelist restrictions
        require(registry[msg.sender]);

        uint numTokens = computeTokenAmount(msg.sender, amount);
        assert(numTokens &gt; 0);

        // update the total amount raised
        amountRaised = amountRaised.add(amount);
        require(amountRaised &lt;= fundingCap);

        // update the sender&#39;s balance of wei contributed
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        // add to the token balance of the sender
        tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(numTokens);

        FundTransfer(msg.sender, amount, true);
        updateFundingCap();
    }

    /**
    * Computes the amount of QSP that should be issued for the given transaction.
    * Contribution tiers are filled up in the order 3, 2, 1, 4.
    * @param addr      The wallet address of the contributor
    * @param amount    Amount of wei for payment
    */
    function computeTokenAmount(address addr, uint amount) internal
        returns (uint){
        require(amount &gt; 0);

        uint r3 = cap3[addr].sub(contributed3[addr]);
        uint r2 = cap2[addr].sub(contributed2[addr]);
        uint r1 = cap1[addr].sub(contributed1[addr]);
        uint r4 = cap4[addr].sub(contributed4[addr]);
        uint numTokens = 0;

        // cannot contribute more than the remaining sum
        assert(amount &lt;= r3.add(r2).add(r1).add(r4));

        // Compute tokens for tier 3
        if(r3 &gt; 0){
            if(amount &lt;= r3){
                contributed3[addr] = contributed3[addr].add(amount);
                return rate3.mul(amount);
            }
            else{
                numTokens = rate3.mul(r3);
                amount = amount.sub(r3);
                contributed3[addr] = cap3[addr];
            }
        }
        // Compute tokens for tier 2
        if(r2 &gt; 0){
            if(amount &lt;= r2){
                contributed2[addr] = contributed2[addr].add(amount);
                return numTokens.add(rate2.mul(amount));
            }
            else{
                numTokens = numTokens.add(rate2.mul(r2));
                amount = amount.sub(r2);
                contributed2[addr] = cap2[addr];
            }
        }
        // Compute tokens for tier 1
        if(r1 &gt; 0){
            if(amount &lt;= r1){
                contributed1[addr] = contributed1[addr].add(amount);
                return numTokens.add(rate1.mul(amount));
            }
            else{
                numTokens = numTokens.add(rate1.mul(r1));
                amount = amount.sub(r1);
                contributed1[addr] = cap1[addr];
            }
        }
        // Compute tokens for tier 4 (overflow)
        contributed4[addr] = contributed4[addr].add(amount);
        return numTokens.add(rate4.mul(amount));
    }

    /**
     * @dev Check if a contributor was at any point registered.
     *
     * @param contributor Address that will be checked.
     */
    function hasPreviouslyRegistered(address contributor)
        internal
        constant
        onlyOwner returns (bool)
    {
        // if caps for this customer exist, then the customer has previously been registered
        return (cap1[contributor].add(cap2[contributor]).add(cap3[contributor]).add(cap4[contributor])) &gt; 0;
    }

    /*
    * If the user was already registered, ensure that the new caps do not conflict previous contributions
    *
    * NOTE: cannot use SafeMath here, because it exceeds the local variable stack limit.
    * Should be ok since it is onlyOwner, and conditionals should guard the subtractions from underflow.
    */
    function validateUpdatedRegistration(address addr, uint c1, uint c2, uint c3, uint c4)
        internal
        constant
        onlyOwner returns(bool)
    {
        return (contributed3[addr] &lt;= c3) &amp;&amp; (contributed2[addr] &lt;= c2)
            &amp;&amp; (contributed1[addr] &lt;= c1) &amp;&amp; (contributed4[addr] &lt;= c4);
    }

    /**
     * @dev Sets registration status of an address for participation.
     *
     * @param contributor Address that will be registered/deregistered.
     * @param c1 The maximum amount of wei that the user can contribute in tier 1.
     * @param c2 The maximum amount of wei that the user can contribute in tier 2.
     * @param c3 The maximum amount of wei that the user can contribute in tier 3.
     * @param c4 The maximum amount of wei that the user can contribute in tier 4.
     */
    function registerUser(address contributor, uint c1, uint c2, uint c3, uint c4)
        public
        onlyOwner
    {
        require(contributor != address(0));
        // if the user was already registered ensure that the new caps do not contradict their current contributions
        if(hasPreviouslyRegistered(contributor)){
            require(validateUpdatedRegistration(contributor, c1, c2, c3, c4));
        }
        require(c1.add(c2).add(c3).add(c4) &gt;= minContribution);
        registry[contributor] = true;
        cap1[contributor] = c1;
        cap2[contributor] = c2;
        cap3[contributor] = c3;
        cap4[contributor] = c4;
        RegistrationStatusChanged(contributor, true, c1, c2, c3, c4);
    }

     /**
     * @dev Remove registration status of an address for participation.
     *
     * NOTE: if the user made initial contributions to the crowdsale,
     *       this will not return the previously allotted tokens.
     *
     * @param contributor Address to be unregistered.
     */
    function deactivate(address contributor)
        public
        onlyOwner
    {
        require(registry[contributor]);
        registry[contributor] = false;
        RegistrationStatusChanged(contributor, false, cap1[contributor], cap2[contributor], cap3[contributor], cap4[contributor]);

    }

    /**
     * @dev Re-registers an already existing contributor
     *
     * @param contributor Address to be unregistered.
     */
    function reactivate(address contributor)
        public
        onlyOwner
    {
        require(hasPreviouslyRegistered(contributor));
        registry[contributor] = true;
        RegistrationStatusChanged(contributor, true, cap1[contributor], cap2[contributor], cap3[contributor], cap4[contributor]);

    }

    /**
     * @dev Sets registration statuses of addresses for participation.
     * @param contributors Addresses that will be registered/deregistered.
     * @param caps1 The maximum amount of wei that each user can contribute to cap1, in the same order as the addresses.
     * @param caps2 The maximum amount of wei that each user can contribute to cap2, in the same order as the addresses.
     * @param caps3 The maximum amount of wei that each user can contribute to cap3, in the same order as the addresses.
     * @param caps4 The maximum amount of wei that each user can contribute to cap4, in the same order as the addresses.
     */
    function registerUsers(address[] contributors,
                           uint[] caps1,
                           uint[] caps2,
                           uint[] caps3,
                           uint[] caps4)
        external
        onlyOwner
    {
        // check that all arrays have the same length
        require(contributors.length == caps1.length);
        require(contributors.length == caps2.length);
        require(contributors.length == caps3.length);
        require(contributors.length == caps4.length);

        for (uint i = 0; i &lt; contributors.length; i++) {
            registerUser(contributors[i], caps1[i], caps2[i], caps3[i], caps4[i]);
        }
    }

    /**
     * The owner can terminate the crowdsale at any time.
     */
    function terminate() external onlyOwner {
        saleClosed = true;
    }

    /**
     * The owner can allocate the specified amount of tokens from the
     * crowdsale allowance to the recipient addresses.
     *
     * NOTE: be extremely careful to get the amounts correct, which
     * are in units of wei and mini-QSP. Every digit counts.
     *
     * @param addrs          the recipient addresses
     * @param weiAmounts     the amounts contributed in wei
     * @param miniQspAmounts the amounts of tokens transferred in mini-QSP
     */
    function ownerAllocateTokensForList(address[] addrs, uint[] weiAmounts, uint[] miniQspAmounts)
            external onlyOwner
    {
        require(addrs.length == weiAmounts.length);
        require(addrs.length == miniQspAmounts.length);
        for(uint i = 0; i &lt; addrs.length; i++){
            ownerAllocateTokens(addrs[i], weiAmounts[i], miniQspAmounts[i]);
        }
    }

    /**
     *
     * The owner can allocate the specified amount of tokens from the
     * crowdsale allowance to the recipient (_to).
     *
     *
     *
     * NOTE: be extremely careful to get the amounts correct, which
     * are in units of wei and mini-QSP. Every digit counts.
     *
     * @param _to            the recipient of the tokens
     * @param amountWei     the amount contributed in wei
     * @param amountMiniQsp the amount of tokens transferred in mini-QSP
     */
    function ownerAllocateTokens(address _to, uint amountWei, uint amountMiniQsp)
            onlyOwner nonReentrant
    {
        // don&#39;t allocate tokens for the admin
        // require(tokenReward.adminAddr() != _to);

        amountRaised = amountRaised.add(amountWei);
        require(amountRaised &lt;= fundingCap);

        tokenBalanceOf[_to] = tokenBalanceOf[_to].add(amountMiniQsp);
        balanceOf[_to] = balanceOf[_to].add(amountWei);

        FundTransfer(_to, amountWei, true);
        updateFundingCap();
    }


    /**
     * The owner can call this function to withdraw the funds that
     * have been sent to this contract for the crowdsale subject to
     * the funding goal having been reached. The funds will be sent
     * to the beneficiary specified when the crowdsale was created.
     */
    function ownerSafeWithdrawal() external onlyOwner nonReentrant {
        uint balanceToSend = this.balance;
        beneficiary.transfer(balanceToSend);
        FundTransfer(beneficiary, balanceToSend, false);
    }


    /**
     * Checks if the funding cap has been reached. If it has, then
     * the CapReached event is triggered.
     */
    function updateFundingCap() internal {
        assert (amountRaised &lt;= fundingCap);
        if (amountRaised == fundingCap) {
            // Check if the funding cap has been reached
            fundingCapReached = true;
            saleClosed = true;
            CapReached(beneficiary, amountRaised);
        }
    }

    /**
     * Returns the current time.
     * Useful to abstract calls to &quot;now&quot; for tests.
    */
    function currentTime() constant returns (uint _currentTime) {
        return now;
    }
}

/**
 * The ExtendedQuantstampSale smart contract is used for selling QuantstampToken
 * tokens (QSP). It does so by converting ETH received into a quantity of
 * tokens that are transferred to the contributor via the ERC20-compatible
 * transferFrom() function.
 */
contract ExtendedQuantstampSale is Pausable {

    using SafeMath for uint256;
    address public beneficiary;
    uint public fundingCap;
    uint public minContribution;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

    // Whitelist data
    mapping(address =&gt; bool) public registry;
    mapping(address =&gt; uint256) public cap;

    // Time period of sale (UNIX timestamps)
    uint public startTime;
    uint public endTime;

    // Keeps track of the amount of wei raised
    uint public amountRaised;

    // prevent certain functions from being recursively called
    bool private rentrancy_lock = false;

    // A map that tracks the amount of wei contributed by address
    mapping(address =&gt; uint256) public balanceOf;

    // Previously created contract
    QuantstampSale public previousContract;

    // Events
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event RegistrationStatusChanged(address target, bool isRegistered, uint c);

    // Modifiers
    modifier beforeDeadline()   {  require (currentTime() &lt; endTime); _;     }
    modifier afterStartTime()   {  require (currentTime() &gt;= startTime); _;  }
    modifier saleNotClosed()    {  require (!saleClosed); _;                 }

    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

    /**
     * Constructor for a crowdsale of QuantstampToken tokens.
     *
     * @param ifSuccessfulSendTo            the beneficiary of the fund
     * @param fundingCapInEthers            the cap (maximum) size of the fund
     * @param minimumContributionInWei      minimum contribution (in wei)
     * @param start                         the start time (UNIX timestamp)
     * @param durationInMinutes             the duration of the crowdsale in minutes
     */
    function ExtendedQuantstampSale(
        address ifSuccessfulSendTo,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint durationInMinutes,
        address previousContractAddress
    ) {
        require(ifSuccessfulSendTo != address(0) &amp;&amp; ifSuccessfulSendTo != address(this));
        require(durationInMinutes &gt; 0);
        beneficiary = ifSuccessfulSendTo;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        endTime = start + (durationInMinutes * 1 minutes);
        previousContract = QuantstampSale(previousContractAddress);
    }

    /**
     * Fallback function that is payable and calls &quot;buy&quot; to purchase tokens.
     */
    function () payable {
        buy();
    }

    /**
     * Buy tokens, subject to the descriptive constraints specified by modifiers.
     */
    function buy ()
        payable public
        whenNotPaused
        beforeDeadline
        afterStartTime
        saleNotClosed
        nonReentrant
    {
        uint amount = msg.value;
        require(amount &gt;= minContribution);

        // ensure that the user adheres to whitelist restrictions
        require(registry[msg.sender]);

        // update the amount raised
        amountRaised = amountRaised.add(amount);
        require(getTotalAmountRaised() &lt;= fundingCap);

        // update the sender&#39;s balance of wei contributed
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        require(getUserBalance(msg.sender) &lt;= cap[msg.sender]);

        FundTransfer(msg.sender, amount, true);
        updateFundingCap();
    }

    function getTotalAmountRaised() public constant returns (uint) {
        return amountRaised.add(previousContract.amountRaised());
    }

    function getUserBalance(address user) public constant returns (uint) {
        return balanceOf[user].add(previousContract.balanceOf(user));
    }

    function setEndTime(uint timestamp) public onlyOwner {
        endTime = timestamp;
    }

    /**
     * @dev Check if a contributor was at any point registered.
     *
     * @param contributor Address that will be checked.
     */
    function hasPreviouslyRegistered(address contributor)
        internal
        constant
        returns (bool)
    {
        // if a cap for this customer exist, then the customer has previously been registered
        // we skip the caps from the previous contract
        return cap[contributor] &gt; 0;
    }

    /*
     * If the user was already registered, ensure that the new caps do not conflict previous contributions
     */
    function validateUpdatedRegistration(address addr, uint _cap)
        internal
        constant
        returns(bool)
    {
        return (getUserBalance(addr) &lt;= _cap);
    }

    /**
     * @dev Sets registration status of an address for participation.
     *
     * @param contributor Address that will be registered/deregistered.
     * @param _cap The maximum amount of wei that the user can contribute
     */
    function registerUser(address contributor, uint _cap)
        public
        onlyOwner
    {
        require(contributor != address(0));
        // if the user was already registered ensure that the new caps do not contradict their current contributions
        if(hasPreviouslyRegistered(contributor)){
            require(validateUpdatedRegistration(contributor, _cap));
        }
        require(_cap &gt;= minContribution);
        registry[contributor] = true;
        cap[contributor] = _cap;
        RegistrationStatusChanged(contributor, true, _cap);
    }

     /**
     * @dev Remove registration status of an address for participation.
     *
     * NOTE: if the user made initial contributions to the crowdsale,
     *       this will not return the previously allotted tokens.
     *
     * @param contributor Address to be unregistered.
     */
    function deactivate(address contributor)
        public
        onlyOwner
    {
        require(registry[contributor]);
        registry[contributor] = false;
        RegistrationStatusChanged(contributor, false, cap[contributor]);

    }

    /**
     * @dev Re-registers an already existing contributor
     *
     * @param contributor Address to be unregistered.
     */
    function reactivate(address contributor)
        public
        onlyOwner
    {
        require(hasPreviouslyRegistered(contributor));
        registry[contributor] = true;
        RegistrationStatusChanged(contributor, true, cap[contributor]);
    }

    /**
     * @dev Sets registration statuses of addresses for participation.
     * @param contributors Addresses that will be registered/deregistered.
     * @param caps The maximum amount of wei that each user can contribute to cap, in the same order as the addresses.
     */
    function registerUsers(address[] contributors, uint[] caps) external
        onlyOwner
    {
        // check that all arrays have the same length
        require(contributors.length == caps.length);

        for (uint i = 0; i &lt; contributors.length; i++) {
            registerUser(contributors[i], caps[i]);
        }
    }

    /**
     * The owner can terminate the crowdsale at any time.
     */
    function terminate() external
        onlyOwner
    {
        saleClosed = true;
    }

    /**
     *
     * The owner can allocate the specified amount.
     *
     * @param _to            the recipient of the tokens
     * @param amountWei     the amount contributed in wei
     */
    function ownerAllocate(address _to, uint amountWei) public
        onlyOwner
        nonReentrant
    {
        amountRaised = amountRaised.add(amountWei);
        require(getTotalAmountRaised() &lt;= fundingCap);

        balanceOf[_to] = balanceOf[_to].add(amountWei);

        FundTransfer(_to, amountWei, true);
        updateFundingCap();
    }


    /**
     * The owner can call this function to withdraw the funds that
     * have been sent to this contract for the crowdsale subject to
     * the funding goal having been reached. The funds will be sent
     * to the beneficiary specified when the crowdsale was created.
     */
    function ownerSafeWithdrawal() external
        onlyOwner
        nonReentrant
    {
        uint balanceToSend = this.balance;
        beneficiary.transfer(balanceToSend);
        FundTransfer(beneficiary, balanceToSend, false);
    }


    /**
     * Checks if the funding cap has been reached. If it has, then
     * the CapReached event is triggered.
     */
    function updateFundingCap() internal
    {
        uint amount = getTotalAmountRaised();
        assert (amount &lt;= fundingCap);
        if (amount == fundingCap) {
            // Check if the funding cap has been reached
            fundingCapReached = true;
            saleClosed = true;
            CapReached(beneficiary, amount);
        }
    }

    /**
     * Returns the current time.
     * Useful to abstract calls to &quot;now&quot; for tests.
    */
    function currentTime() public constant returns (uint _currentTime)
    {
        return now;
    }
}