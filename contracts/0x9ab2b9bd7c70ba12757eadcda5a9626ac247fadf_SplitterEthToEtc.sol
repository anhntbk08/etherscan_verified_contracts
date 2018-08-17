contract AmIOnTheFork {
    function forked() constant returns(bool);
}

contract SplitterEthToEtc {

    event OnReceive(uint64);

    struct Received {
        address from;
        uint256 value;
    }

    address intermediate;
    address owner;
    mapping (uint64 =&gt; Received) public received;
    uint64 public seq = 1;

    // there is a limit accepted by exchange
    uint256 public upLimit = 50 ether;
    // and exchange costs, ignore small transactions
    uint256 public lowLimit = 0.1 ether;

    AmIOnTheFork amIOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);

    function SplitterEthToEtc() {
        owner = msg.sender;
    }

    function() {
        //stop too small transactions
        if (msg.value &lt; lowLimit) throw;

        // process with exchange on the FORK chain
        if (amIOnTheFork.forked()) {
            // check that received less or equal to conversion up limit
            if (msg.value &lt;= upLimit) {
                if (!intermediate.send(msg.value)) throw;
                uint64 id = seq++;
                received[id] = Received(msg.sender, msg.value);
                OnReceive(id);
            } else {
                // send only acceptable value, return rest
                if (!intermediate.send(upLimit)) throw;
                if (!msg.sender.send(msg.value - upLimit)) throw;
                uint64 idp = seq++;
                received[id] = Received(msg.sender, upLimit);
                OnReceive(id);
            }

        // always return value from CLASSIC chain
        } else {
            if (!msg.sender.send(msg.value)) throw;
        }
    }

    function processed(uint64 _id) {
        if (msg.sender != owner) throw;
        delete received[_id];
    }

    function setIntermediate(address _intermediate) {
        if (msg.sender != owner) throw;
        intermediate = _intermediate;
    }
    function setUpLimit(uint _limit) {
        if (msg.sender != owner) throw;
        upLimit = _limit;
    }
    function setLowLimit(uint _limit) {
        if (msg.sender != owner) throw;
        lowLimit = _limit;
    }

}