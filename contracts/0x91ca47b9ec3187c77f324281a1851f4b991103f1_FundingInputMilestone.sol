pragma solidity ^0.4.17;

/*

 * source       https://github.com/blockbitsio/

 * @name        General Funding Input Contract
 * @package     BlockBitsIO
 * @author      Micky Socaci &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bad7d3d9d1c3fad4d5cdd6d3ccdf94c8d5">[email&#160;protected]</a>&gt;

*/



contract FundingInputGeneral {

    bool public initialized = false;
    uint8 public typeId = 0;
    address public FundingAssetAddress;
    address public deployer;

    event EventInputPaymentReceived(address sender, uint amount, uint8 _type);

    function FundingInputGeneral() public {
        deployer = msg.sender;
    }

    function setFundingAssetAddress(address _addr) public {
        require(initialized == false &amp;&amp; msg.sender == deployer);
        FundingAssetAddress = _addr;
        initialized = true;
    }

    function () public payable {
        buy();
    }

    function buy() public payable returns(bool) {
        if(msg.value &gt; 0) {
            if(isContract(FundingAssetAddress)) {
                if(FundingAssetAddress.call.value(msg.value)(bytes4(bytes32(keccak256(&quot;receivePayment(address,uint8)&quot;))), msg.sender, typeId)) {
                    EventInputPaymentReceived(msg.sender, msg.value, typeId);
                    return true;
                } else {
                    revert();
                }
            }
            else {
                revert();
            }
        } else {
            revert();
        }
    }

    // this call adds 704 gas, good enough to keep
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size &gt; 0;
    }
}

/*

 * source       https://github.com/blockbitsio/

 * @name        Milestone Funding Input Contract
 * @package     BlockBitsIO
 * @author      Micky Socaci &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cda0a4aea6b48da3a2baa1a4bba8e3bfa2">[email&#160;protected]</a>&gt;

*/





contract FundingInputMilestone is FundingInputGeneral {
    function FundingInputMilestone() FundingInputGeneral() public {
        typeId = 2;
    }
}