/**
 * This is a multisig wallet based on Gav&#39;s original implementation, daily withdraw limits removed.
 *
 *
 * For other multisig wallet implementations, see https://blog.gnosis.pm/release-of-new-multisig-wallet-59b6811f7edc
 */

// Multi-sig, daily-limited account proxy/wallet.
// @authors:
// Gav Wood &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e98ea98c9d818d8c9fc78a8684">[email&#160;protected]</a>&gt;
// inheritable &quot;property&quot; contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.
contract multiowned {

	// TYPES

    // struct for the status of a pending operation.
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

	// EVENTS

    // this contract only has six types of events: it can accept a confirmation, in which case
    // we record owner and operation (hash) alongside it.
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

	// MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

	// METHODS

    // constructor is given number of sigs required to do protected &quot;onlymanyowners&quot; transactions
    // as well as the selection of addresses capable of confirming them.
    function multiowned(address[] _owners, uint _required) {
        m_numOwners = _owners.length + 1;
        m_owners[1] = uint(msg.sender);
        m_ownerIndex[uint(msg.sender)] = 1;
        for (uint i = 0; i &lt; _owners.length; ++i)
        {
            m_owners[2 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 2 + i;
        }
        m_required = _required;
    }

    // Revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they&#39;re an owner
        if (ownerIndex == 0) return;
        uint ownerIndexBit = 2**ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone &amp; ownerIndexBit &gt; 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }

    // Replaces an owner `_from` with another `_to`.
    function changeOwner(address _from, address _to) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }

    function addOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_owner)) return;

        clearPending();
        if (m_numOwners &gt;= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners &gt;= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner);
    }

    function removeOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        if (m_required &gt; m_numOwners - 1) return;

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners(); //make sure m_numOwner is equal to the number of owners and always points to the optimal free slot
        OwnerRemoved(_owner);
    }

    function changeRequirement(uint _newRequired) onlymanyowners(sha3(msg.data)) external {
        if (_newRequired &gt; m_numOwners) return;
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

    // Gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) external constant returns (address) {
        return address(m_owners[ownerIndex + 1]);
    }

    function isOwner(address _addr) returns (bool) {
        return m_ownerIndex[uint(_addr)] &gt; 0;
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

        // make sure they&#39;re an owner
        if (ownerIndex == 0) return false;

        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        return !(pending.ownersDone &amp; ownerIndexBit == 0);
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
        // determine what index the present sender is:
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they&#39;re an owner
        if (ownerIndex == 0) return;

        var pending = m_pending[_operation];
        // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_required;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        // make sure we (the message sender) haven&#39;t confirmed this operation previously.
        if (pending.ownersDone &amp; ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead.
            if (pending.yetNeeded &lt;= 1) {
                // enough confirmations: reset and run interior.
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            }
            else
            {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free &lt; m_numOwners)
        {
            while (free &lt; m_numOwners &amp;&amp; m_owners[free] != 0) free++;
            while (m_numOwners &gt; 1 &amp;&amp; m_owners[m_numOwners] == 0) m_numOwners--;
            if (free &lt; m_numOwners &amp;&amp; m_owners[m_numOwners] != 0 &amp;&amp; m_owners[free] == 0)
            {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i &lt; length; ++i)
            if (m_pendingIndex[i] != 0)
                delete m_pending[m_pendingIndex[i]];
        delete m_pendingIndex;
    }

   	// FIELDS

    // the number of owners that must confirm the same operation before it is run.
    uint public m_required;
    // pointer used to find a free slot in m_owners
    uint public m_numOwners;

    // list of owners
    uint[256] m_owners;
    uint constant c_maxOwners = 250;
    // index on the list of owners to allow reverse lookup
    mapping(uint =&gt; uint) m_ownerIndex;
    // the ongoing operations.
    mapping(bytes32 =&gt; PendingState) m_pending;
    bytes32[] m_pendingIndex;
}

// inheritable &quot;property&quot; contract that enables methods to be protected by placing a linear limit (specifiable)
// on a particular resource per calendar day. is multiowned to allow the limit to be altered. resource that method
// uses is specified in the modifier.
contract daylimit is multiowned {

	// MODIFIERS

    // simple modifier for daily limit.
    modifier limitedDaily(uint _value) {
        if (underLimit(_value))
            _;
    }

	// METHODS

    // constructor - stores initial daily limit and records the present day&#39;s index.
    function daylimit(uint _limit) {
        m_dailyLimit = _limit;
        m_lastDay = today();
    }
    // (re)sets the daily limit. needs many of the owners to confirm. doesn&#39;t alter the amount already spent today.
    function setDailyLimit(uint _newLimit) onlymanyowners(sha3(msg.data)) external {
        m_dailyLimit = _newLimit;
    }
    // resets the amount already spent today. needs many of the owners to confirm.
    function resetSpentToday() onlymanyowners(sha3(msg.data)) external {
        m_spentToday = 0;
    }

    // INTERNAL METHODS

    // checks to see if there is at least `_value` left from the daily limit today. if there is, subtracts it and
    // returns true. otherwise just returns false.
    function underLimit(uint _value) internal onlyowner returns (bool) {
        // reset the spend limit if we&#39;re on a different day to last time.
        /*if (today() &gt; m_lastDay) {
            m_spentToday = 0;
            m_lastDay = today();
        }
        // check to see if there&#39;s enough left - if so, subtract and return true.
        // overflow protection                    // dailyLimit check
        if (m_spentToday + _value &gt;= m_spentToday &amp;&amp; m_spentToday + _value &lt;= m_dailyLimit) {
            m_spentToday += _value;
            return true;
        }
        return false;*/
        return false;
    }
    // determines today&#39;s index.
    function today() private constant returns (uint) { return now / 1 days; }

	// FIELDS

    uint public m_dailyLimit;
    uint public m_spentToday;
    uint public m_lastDay;
}

// interface contract for multisig proxy contracts; see below for docs.
contract multisig {

	// EVENTS

    // logged events:
    // Funds has arrived into the wallet (record how much).
    event Deposit(address _from, uint value);
    // Single transaction going out of the wallet (record who signed for it, how much, and to whom it&#39;s going).
    event SingleTransact(address owner, uint value, address to, bytes data);
    // Multi-sig transaction going out of the wallet (record who signed for it last, the operation hash, how much, and to whom it&#39;s going).
    event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data);
    // Confirmation still needed for a transaction.
    event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);

    // FUNCTIONS

    // TODO: document
    function changeOwner(address _from, address _to) external;
    function execute(address _to, uint _value, bytes _data) external returns (bytes32);
    function confirm(bytes32 _h) returns (bool);
}

// usage:
// bytes32 h = Wallet(w).from(oneOwner).transact(to, value, data);
// Wallet(w).from(anotherOwner).confirm(h);
contract Wallet is multisig, multiowned, daylimit {

	// TYPES

    // Transaction structure to remember details of transaction lest it need be saved for a later call.
    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

    // METHODS

    // constructor - just pass on the owner array to the multiowned and
    // the limit to daylimit
    function Wallet(address[] _owners, uint _required, uint _daylimit)
            multiowned(_owners, _required) daylimit(_daylimit) {
    }

    // kills the contract sending everything to `_to`.
    function kill(address _to) onlymanyowners(sha3(msg.data)) external {
        suicide(_to);
    }

    // gets called when no other function matches
    function() payable {
        // just being sent some cash?
        if (msg.value &gt; 0)
            Deposit(msg.sender, msg.value);
    }

    // Outside-visible transact entry point. Executes transaction immediately if below daily spend limit.
    // If not, goes into multisig process. We provide a hash on return to allow the sender to provide
    // shortcuts for the other confirmations (allowing them to avoid replicating the _to, _value
    // and _data arguments). They still get the option of using them if they want, anyways.
    function execute(address _to, uint _value, bytes _data) external onlyowner returns (bytes32 _r) {
        // first, take the opportunity to check that we&#39;re under the daily limit.
        if (underLimit(_value)) {
            SingleTransact(msg.sender, _value, _to, _data);
            // yes - just execute the call.
            _to.call.value(_value)(_data);
            return 0;
        }
        // determine our operation hash.
        _r = sha3(msg.data, block.number);
        if (!confirm(_r) &amp;&amp; m_txs[_r].to == 0) {
            m_txs[_r].to = _to;
            m_txs[_r].value = _value;
            m_txs[_r].data = _data;
            ConfirmationNeeded(_r, msg.sender, _value, _to, _data);
        }
    }

    // confirm a transaction through just the hash. we use the previous transactions map, m_txs, in order
    // to determine the body of the transaction from the hash provided.
    function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
        if (m_txs[_h].to != 0) {
            m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data);
            MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to, m_txs[_h].data);
            delete m_txs[_h];
            return true;
        }
    }

    // INTERNAL METHODS

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i &lt; length; ++i)
            delete m_txs[m_pendingIndex[i]];
        super.clearPending();
    }

	// FIELDS

    // pending transactions we have at present.
    mapping (bytes32 =&gt; Transaction) m_txs;
}