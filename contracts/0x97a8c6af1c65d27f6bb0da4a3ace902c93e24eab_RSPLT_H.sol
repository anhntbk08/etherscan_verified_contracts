pragma solidity ^0.4.6;

// --------------------------
//  R Split Contract
// --------------------------
contract RSPLT_H {
        event StatEvent(string msg);
        event StatEventI(string msg, uint val);

        enum SettingStateValue  {debug, locked}

        struct partnerAccount {
                uint credited;  // total funds credited to this account
                uint balance;   // current balance = credited - amount withdrawn
                uint pctx10;     // percent allocation times ten
                address addr;   // payout addr of this acct
                bool evenStart; // even split up to evenDistThresh
        }

// -----------------------------
//  data storage
// ----------------------------------------
        address public owner;                                // deployer executor
        mapping (uint =&gt; partnerAccount) partnerAccounts;    // accounts by index
        uint public numAccounts;                             // how many accounts exist
        uint public holdoverBalance;                         // amount yet to be distributed
        uint public totalFundsReceived;                      // amount received since begin of time
        uint public totalFundsDistributed;                   // amount distributed since begin of time
        uint public totalFundsWithdrawn;                     // amount withdrawn since begin of time
        uint public evenDistThresh;                          // distribute evenly until this amount (total)
        uint public withdrawGas = 35000;                     // gas for withdrawals
        uint constant TENHUNDWEI = 1000;                     // need gt. 1000 wei to do payout
        uint constant MAX_ACCOUNTS = 5;                      // max accounts this contract can handle
        SettingStateValue public settingsState = SettingStateValue.debug; 


        // --------------------
        // contract constructor
        // --------------------
        function RSPLT_H() {
                owner = msg.sender;
        }


        // -----------------------------------
        // lock
        // lock the contract. after calling this you will not be able to modify accounts:
        // -----------------------------------
        function lock() {
                if (msg.sender != owner) {
                        StatEvent(&quot;err: not owner&quot;);
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent(&quot;err: locked&quot;);
                        return;
                }
                settingsState = SettingStateValue.locked;
                StatEvent(&quot;ok: contract locked&quot;);
        }


        // -----------------------------------
        // reset
        // reset all accounts
        // -----------------------------------
        function reset() {
                if (msg.sender != owner) {
                        StatEvent(&quot;err: not owner&quot;);
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent(&quot;err: locked&quot;);
                        return;
                }
                numAccounts = 0;
                holdoverBalance = 0;
                totalFundsReceived = 0;
                totalFundsDistributed = 0;
                totalFundsWithdrawn = 0;
                StatEvent(&quot;ok: all accts reset&quot;);
        }


        // -----------------------------------
        // set even distribution threshold
        // -----------------------------------
        function setEvenDistThresh(uint256 _thresh) {
                if (msg.sender != owner) {
                        StatEvent(&quot;err: not owner&quot;);
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent(&quot;err: locked&quot;);
                        return;
                }
                evenDistThresh = (_thresh / TENHUNDWEI) * TENHUNDWEI;
                StatEventI(&quot;ok: threshold set&quot;, evenDistThresh);
        }


        // -----------------------------------
        // set even distribution threshold
        // -----------------------------------
        function setWitdrawGas(uint256 _withdrawGas) {
                if (msg.sender != owner) {
                        StatEvent(&quot;err: not owner&quot;);
                        return;
                }
                withdrawGas = _withdrawGas;
                StatEventI(&quot;ok: withdraw gas set&quot;, withdrawGas);
        }


        // ---------------------------------------------------
        // add a new account
        // ---------------------------------------------------
        function addAccount(address _addr, uint256 _pctx10, bool _evenStart) {
                if (msg.sender != owner) {
                        StatEvent(&quot;err: not owner&quot;);
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent(&quot;err: locked&quot;);
                        return;
                }
                if (numAccounts &gt;= MAX_ACCOUNTS) {
                        StatEvent(&quot;err: max accounts&quot;);
                        return;
                }
                partnerAccounts[numAccounts].addr = _addr;
                partnerAccounts[numAccounts].pctx10 = _pctx10;
                partnerAccounts[numAccounts].evenStart = _evenStart;
                partnerAccounts[numAccounts].credited = 0;
                partnerAccounts[numAccounts].balance = 0;
                ++numAccounts;
                StatEvent(&quot;ok: acct added&quot;);
        }


        // ----------------------------
        // get acct info
        // ----------------------------
        function getAccountInfo(address _addr) constant returns(uint _idx, uint _pctx10, bool _evenStart, uint _credited, uint _balance) {
                for (uint i = 0; i &lt; numAccounts; i++ ) {
                        address addr = partnerAccounts[i].addr;
                        if (addr == _addr) {
                                _idx = i;
                                _pctx10 = partnerAccounts[i].pctx10;
                                _evenStart = partnerAccounts[i].evenStart;
                                _credited = partnerAccounts[i].credited;
                                _balance = partnerAccounts[i].balance;
                                StatEvent(&quot;ok: found acct&quot;);
                                return;
                        }
                }
                StatEvent(&quot;err: acct not found&quot;);
        }


        // ----------------------------
        // get total percentages x10
        // ----------------------------
        function getTotalPctx10() constant returns(uint _totalPctx10) {
                _totalPctx10 = 0;
                for (uint i = 0; i &lt; numAccounts; i++ ) {
                        _totalPctx10 += partnerAccounts[i].pctx10;
                }
                StatEventI(&quot;ok: total pctx10&quot;, _totalPctx10);
        }


        // ----------------------------
        // get no. accts that are set for even split
        // ----------------------------
        function getNumEvenSplits() constant returns(uint _numEvenSplits) {
                _numEvenSplits = 0;
                for (uint i = 0; i &lt; numAccounts; i++ ) {
                        if (partnerAccounts[i].evenStart) {
                                ++_numEvenSplits;
                        }
                }
                StatEventI(&quot;ok: even splits&quot;, _numEvenSplits);
        }


        // -------------------------------------------
        // default payable function.
        // call us with plenty of gas, or catastrophe will ensue
        // note: you can call this fcn with amount of zero to force distribution
        // -------------------------------------------
        function () payable {
                totalFundsReceived += msg.value;
                holdoverBalance += msg.value;
                StatEventI(&quot;ok: incoming&quot;, msg.value);
        }


        // ----------------------------
        // distribute funds to all partners
        // ----------------------------
        function distribute() {
                //only payout if we have more than 1000 wei
                if (holdoverBalance &lt; TENHUNDWEI) {
                        return;
                }
                //first pay accounts that are not constrained by even distribution
                //each account gets their prescribed percentage of this holdover.
                uint i;
                uint pctx10;
                uint acctDist;
                uint maxAcctDist;
                uint numEvenSplits = 0;
                for (i = 0; i &lt; numAccounts; i++ ) {
                        if (partnerAccounts[i].evenStart) {
                                ++numEvenSplits;
                        } else {
                                pctx10 = partnerAccounts[i].pctx10;
                                acctDist = holdoverBalance * pctx10 / TENHUNDWEI;
                                //we also double check to ensure that the amount awarded cannot exceed the
                                //total amount due to this acct. note: this check is necessary, cuz here we
                                //might not distribute the full holdover amount during each pass.
                                maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
                                if (partnerAccounts[i].credited &gt;= maxAcctDist) {
                                        acctDist = 0;
                                } else if (partnerAccounts[i].credited + acctDist &gt; maxAcctDist) {
                                        acctDist = maxAcctDist - partnerAccounts[i].credited;
                                }
                                partnerAccounts[i].credited += acctDist;
                                partnerAccounts[i].balance += acctDist;
                                totalFundsDistributed += acctDist;
                                holdoverBalance -= acctDist;
                        }
                }
                //now pay accounts that are constrained by even distribution. we split whatever is
                //left of the holdover evenly.
                uint distAmount = holdoverBalance;
                if (totalFundsDistributed &lt; evenDistThresh) {
                        for (i = 0; i &lt; numAccounts; i++ ) {
                                if (partnerAccounts[i].evenStart) {
                                        acctDist = distAmount / numEvenSplits;
                                        //we also double check to ensure that the amount awarded cannot exceed the
                                        //total amount due to this acct. note: this check is necessary, cuz here we
                                        //might not distribute the full holdover amount during each pass.
                                        uint fundLimit = totalFundsReceived;
                                        if (fundLimit &gt; evenDistThresh)
                                                fundLimit = evenDistThresh;
                                        maxAcctDist = fundLimit / numEvenSplits;
                                        if (partnerAccounts[i].credited &gt;= maxAcctDist) {
                                                acctDist = 0;
                                        } else if (partnerAccounts[i].credited + acctDist &gt; maxAcctDist) {
                                                acctDist = maxAcctDist - partnerAccounts[i].credited;
                                        }
                                        partnerAccounts[i].credited += acctDist;
                                        partnerAccounts[i].balance += acctDist;
                                        totalFundsDistributed += acctDist;
                                        holdoverBalance -= acctDist;
                                }
                        }
                }
                //now, if there are any funds left then it means that we have either exceeded the even distribution threshold,
                //or there is a remainder in the even split. in that case distribute all the remmaing funds to partners who have
                //not yet exceeded their allotment, according to their &quot;effective&quot; percentages. note that this must be done here,
                //even if we haven&#39;t passed the even distribution threshold, to ensure that we don&#39;t get stuck with a remainder
                //amount that cannot be distributed.
                distAmount = holdoverBalance;
                if (distAmount &gt; 0) {
                        uint totalDistPctx10 = 0;
                        for (i = 0; i &lt; numAccounts; i++ ) {
                                pctx10 = partnerAccounts[i].pctx10;
                                maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
                                if (partnerAccounts[i].credited &lt; maxAcctDist) {
                                        totalDistPctx10 += pctx10;
                                }
                        }
                        for (i = 0; i &lt; numAccounts; i++ ) {
                                pctx10 = partnerAccounts[i].pctx10;
                                acctDist = distAmount * pctx10 / totalDistPctx10;
                                //we also double check to ensure that the amount awarded cannot exceed the
                                //total amount due to this acct. note: this check is necessary, cuz here we
                                //might not distribute the full holdover amount during each pass.
                                maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
                                if (partnerAccounts[i].credited &gt;= maxAcctDist) {
                                        acctDist = 0;
                                } else if (partnerAccounts[i].credited + acctDist &gt; maxAcctDist) {
                                        acctDist = maxAcctDist - partnerAccounts[i].credited;
                                }
                                partnerAccounts[i].credited += acctDist;
                                partnerAccounts[i].balance += acctDist;
                                totalFundsDistributed += acctDist;
                                holdoverBalance -= acctDist;
                        }
                }
                StatEvent(&quot;ok: distributed funds&quot;);
        }


        // ----------------------------
        // withdraw account balance
        // ----------------------------
        function withdraw() {
                for (uint i = 0; i &lt; numAccounts; i++ ) {
                        address addr = partnerAccounts[i].addr;
                        if (addr == msg.sender) {
                                uint amount = partnerAccounts[i].balance;
                                if (amount == 0) { 
                                        StatEvent(&quot;err: balance is zero&quot;);
                                } else {
                                        partnerAccounts[i].balance = 0;
                                        totalFundsWithdrawn += amount;
                                        if (!msg.sender.call.gas(withdrawGas).value(amount)())
                                                throw;
                                        StatEventI(&quot;ok: rewards paid&quot;, amount);
                                }
                        }
                }
        }


        // ----------------------------
        // suicide
        // ----------------------------
        function hariKari() {
                if (msg.sender != owner) {
                        StatEvent(&quot;err: not owner&quot;);
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent(&quot;err: locked&quot;);
                        return;
                }
                suicide(owner);
        }

}