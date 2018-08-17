pragma solidity ^0.4.18;


contract Trigonometry {

    // Table index into the trigonometric table
    uint constant INDEX_WIDTH = 4;
    // Interpolation between successive entries in the tables
    uint constant INTERP_WIDTH = 8;
    uint constant INDEX_OFFSET = 12 - INDEX_WIDTH;
    uint constant INTERP_OFFSET = INDEX_OFFSET - INTERP_WIDTH;
    uint16 constant ANGLES_IN_CYCLE = 16384;
    uint16 constant QUADRANT_HIGH_MASK = 8192;
    uint16 constant QUADRANT_LOW_MASK = 4096;
    uint constant SINE_TABLE_SIZE = 16;

    // constant sine lookup table generated by gen_tables.py
    // We have no other choice but this since constant arrays don&#39;t yet exist
    uint8 constant entry_bytes = 2;
    bytes constant sin_table = &quot;\x00\x00\x0c\x8c\x18\xf9\x25\x28\x30\xfb\x3c\x56\x47\x1c\x51\x33\x5a\x82\x62\xf1\x6a\x6d\x70\xe2\x76\x41\x7a\x7c\x7d\x89\x7f\x61\x7f\xff&quot;;

    /**
     * Convenience function to apply a mask on an integer to extract a certain
     * number of bits. Using exponents since solidity still does not support
     * shifting.
     *
     * @param _value The integer whose bits we want to get
     * @param _width The width of the bits (in bits) we want to extract
     * @param _offset The offset of the bits (in bits) we want to extract
     * @return An integer containing _width bits of _value starting at the
     *         _offset bit
     */
    function bits(uint _value, uint _width, uint _offset) pure internal returns (uint) {
        return (_value / (2 ** _offset)) &amp; (((2 ** _width)) - 1);
    }

    function sin_table_lookup(uint index) pure internal returns (uint16) {
        bytes memory table = sin_table;
        uint offset = (index + 1) * entry_bytes;
        uint16 trigint_value;
        assembly {
            trigint_value := mload(add(table, offset))
        }

        return trigint_value;
    }

    /**
     * Return the sine of an integer approximated angle as a signed 16-bit
     * integer.
     *
     * @param _angle A 14-bit angle. This divides the circle into 16384
     *               angle units, instead of the standard 360 degrees.
     * @return The sine result as a number in the range -32767 to 32767.
     */
    function sin(uint16 _angle) public pure returns (int) {
        uint interp = bits(_angle, INTERP_WIDTH, INTERP_OFFSET);
        uint index = bits(_angle, INDEX_WIDTH, INDEX_OFFSET);

        bool is_odd_quadrant = (_angle &amp; QUADRANT_LOW_MASK) == 0;
        bool is_negative_quadrant = (_angle &amp; QUADRANT_HIGH_MASK) != 0;

        if (!is_odd_quadrant) {
            index = SINE_TABLE_SIZE - 1 - index;
        }

        uint x1 = sin_table_lookup(index);
        uint x2 = sin_table_lookup(index + 1);
        uint approximation = ((x2 - x1) * interp) / (2 ** INTERP_WIDTH);

        int sine;
        if (is_odd_quadrant) {
            sine = int(x1) + int(approximation);
        } else {
            sine = int(x2) - int(approximation);
        }

        if (is_negative_quadrant) {
            sine *= -1;
        }

        return sine;
    }

    /**
     * Return the cos of an integer approximated angle.
     * It functions just like the sin() method but uses the trigonometric
     * identity sin(x + pi/2) = cos(x) to quickly calculate the cos.
     */
    function cos(uint16 _angle) public pure returns (int) {
        if (_angle &gt; ANGLES_IN_CYCLE - QUADRANT_LOW_MASK) {
            _angle = QUADRANT_LOW_MASK - ANGLES_IN_CYCLE - _angle;
        } else {
            _angle += QUADRANT_LOW_MASK;
        }
        return sin(_angle);
    }

}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract VirusGame is Ownable, Trigonometry {

    using SafeMath for uint256;

    /**
    * Structs
    */

    struct Virus {
        bytes32 name;
        bytes32 parent;
        uint256 potential;
        uint256 infected;
        uint256 infectedPayed;
        uint256 infectedTriggle;
        uint256 lastWithdraw;
        uint256 lastInfected;
        uint256 generation;
        address owner;
    }

    /**
    * State
    */

    uint256 nonce;

    mapping (address =&gt; bytes32[]) public virusOwner;

    mapping (bytes32 =&gt; Virus) public virus;

    bytes32[] public virusHashes;

    uint256 public totalPopulation;

    uint256 public totalInfected;

    bytes32 public genesisVirus;

    uint256 public totalBalance;

    uint256 public totalPayed;

    /**
    * Modifier
    */

    modifier useNonce() {
        _;
        nonce = nonce.add(1);
    }

    modifier healthyPeople() {
        require(totalPopulation &gt; totalInfected);
        _;
    }

    /**
    * Functions
    */

    event LogMutation(
        bytes32 parentHash,
        bytes32 virusHash
    );

    function mutate(bytes32 _virus, bytes32 _name) payable healthyPeople useNonce public {
        // ensure parent virus exists
        require(virus[_virus].owner != address(0));

        uint costs = virus[_virus].generation.mul(0.001 ether).add(0.01 ether);
        require(msg.value &gt;= costs);

        bytes32 newHash = keccak256(_virus, _name, nonce, msg.sender, now);

        // new potential from virus hash to uint -&gt; sinus or cosinus
        int mutationFactor = sin(uint16(newHash));
        uint uintFactor;
        uint newPotential;

        if (mutationFactor &gt;= 0) {
            uintFactor = uint(mutationFactor);
            newPotential = virus[_virus].potential.mul(
                uintFactor.mul(20).div(32767).add(100)
            ).div(100);
        } else {
            uintFactor = uint(-mutationFactor);
            newPotential = virus[_virus].potential.mul(
                uintFactor.mul(20).div(32767).add(80)
            ).div(100);
        }

        virus[newHash].name = _name;
        virus[newHash].parent = _virus;
        virus[newHash].generation = virus[_virus].generation.add(1);
        virus[newHash].potential = newPotential;
        virus[newHash].lastInfected = now;
        virus[newHash].lastWithdraw = now;
        virus[newHash].owner = msg.sender;

        virusHashes.push(newHash);
        virusOwner[msg.sender].push(newHash);

        totalBalance = totalBalance.add(
            costs.mul(9).div(10)
        );

        LogMutation(
            _virus,
            newHash
        );
    }

    event LogInfection(
        uint infected,
        bytes32 virusHash
    );

    event LogEndOfWorld();

    function infect(bytes32 _virus) healthyPeople public {
        require(virus[_virus].owner == msg.sender);

        // infectedTriggle + potential * delay = infected
        uint delay = now.sub(virus[_virus].lastInfected);

        uint infected = virus[_virus].infectedTriggle.add(
            virus[_virus].potential.mul(delay).div(1 days)
        );
        
        // infectedTriggle from parent must be set to x% of infected
        virus[virus[_virus].parent].infectedTriggle = virus[virus[_virus].parent].infectedTriggle.add(
            infected.div(10)
        );

        totalInfected = totalInfected.add(infected);
        virus[_virus].infected = virus[_virus].infected.add(infected);

        virus[_virus].lastInfected = now;
        virus[_virus].infectedTriggle = 0;

        LogInfection(
            infected,
            _virus
        );

        if (totalPopulation &lt; totalInfected) {
            totalInfected = totalPopulation;
            LogEndOfWorld();
        }
    }

    function withdraw(bytes32 _virus) public {
        require(virus[_virus].owner == msg.sender);

        // only withdraw once a day
        require(now &gt; (virus[_virus].lastWithdraw + 1 days));

        // calculate ether
        uint toBePayed = virus[_virus].infected.sub(virus[_virus].infectedPayed);
        uint amount = totalBalance.div(totalInfected.sub(totalPayed)).mul(toBePayed);

        require(amount &lt;= totalBalance);

        // subtract from total balance
        totalBalance = totalBalance.sub(amount);
        totalPayed = totalPayed.add(toBePayed);

        // send ether
        msg.sender.transfer(amount);

        virus[_virus].infectedPayed = virus[_virus].infected;
        virus[_virus].lastWithdraw = now;
    }

    function withdrawExcess(address _withdraw) onlyOwner public {
        _withdraw.transfer(this.balance.sub(totalBalance));
    }

    /**
    * Getters
    */

    function getVirusLength() public view returns(uint) {
        return virusHashes.length;
    }

    function getOwnerVirusLength(address _owner) public view returns(uint) {
        return virusOwner[_owner].length;
    }

    /**
    * Constructor
    */

    function VirusGame() public {
        totalPopulation = 7000000000;

        genesisVirus = keccak256(&quot;Genesis&quot;);

        virus[genesisVirus].name = &quot;Genesis&quot;;
        virus[genesisVirus].potential = 100;
        virus[genesisVirus].owner = msg.sender;
        virus[genesisVirus].lastInfected = now;

        virusOwner[msg.sender].push(genesisVirus);
        virusHashes.push(genesisVirus);
    }

}