pragma solidity 0.4.18;


/* 
    Author: Patrick Guay @ Vanbex and Etherparty
    <span class="__cf_email__" data-cfemail="d4a4b5a0a6bdb7bf94a2b5bab6b1acfab7bbb9">[email&#160;protected]</span>
*/

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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract VancouverCharityDrive is Ownable {


    mapping(address =&gt; Pledge[]) public pledges; // keeps all the pledges per address
    mapping(address =&gt; CompanyInfo) public companies; // keeps all the names of companies per address
    address[] public participatingCompanies;

    event PledgeCreated(address indexed pledger, uint256 amount, string companyName);
    event PledgeUpdated(address indexed pledger, uint256 amount, string companyName);
    event PledgeConfirmed(address indexed pledger, uint256 amount, string companyName, string txHash);

    struct CompanyInfo {
        bool initialized;
        string name;
        string email;
        string description;
    }

    struct Pledge {
        bool initialized;
        uint amount; // Amount of the currency used for the pledge
        string charityName; // Name of the charity
        string currency; // Currency used for the pledge
        string txHash; //  TxHash of the pledge
        bool confirmed;
    }

    modifier isWhiteListed() {
        require(companies[msg.sender].initialized == true);
        _;
    }

    function whitelistCompany(address _companyAddress, string _companyName, string _companyEmail, string _description) public onlyOwner returns(bool) {
        companies[_companyAddress] = CompanyInfo(true, _companyName, _companyEmail, _description);
        participatingCompanies.push(_companyAddress);
        return true;
    }

    function createPledge(uint _amount, string _charityName, string _currency) public isWhiteListed returns(bool) {
        pledges[msg.sender].push(Pledge(true, _amount, _charityName, _currency, &quot;&quot;, false));
        PledgeCreated(msg.sender, _amount, companies[msg.sender].name);
        return true;
    }

    function updatePledge(uint _amount, string _charityName, string _currency, uint _pledgeIndex) public isWhiteListed returns(bool) {
        Pledge storage pledge = pledges[msg.sender][_pledgeIndex];
        require(pledge.initialized == true &amp;&amp; pledge.confirmed == false);
        pledge.currency = _currency;
        pledge.amount = _amount;
        pledge.charityName = _charityName;
        return true;
    }

    function confirmPledge(uint _pledgeIndex, string _txHash) public isWhiteListed returns(bool) {
        Pledge storage pledge = pledges[msg.sender][_pledgeIndex];
        require(pledge.initialized == true &amp;&amp; pledge.confirmed == false);
        pledge.txHash = _txHash;
        pledge.confirmed = true;
        PledgeConfirmed(msg.sender, pledge.amount, companies[msg.sender].name, _txHash);
        return true;
    }

    function getPledge(address _companyAddress, uint _index) public view returns (uint amount, string charityName, string currency, string txHash, bool confirmed) {
        amount = pledges[_companyAddress][_index].amount;
        charityName = pledges[_companyAddress][_index].charityName;
        currency = pledges[_companyAddress][_index].currency;
        txHash = pledges[_companyAddress][_index].txHash;
        confirmed = pledges[_companyAddress][_index].confirmed;
    }

    function getAllCompanies() public view returns (address[]) {
        return participatingCompanies;
    }
}