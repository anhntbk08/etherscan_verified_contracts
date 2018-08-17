contract Constants {
	uint256 public constant PRE_ICO_RISK_PERCENTAGE = 5;
	uint256 public constant TEAM_SHARE_PERCENTAGE = 16;
	uint256 public constant blocksByDay = 6306;
	uint256 public constant coinMultiplayer = (10**18);
	
	uint256 public constant PRICE_PREICO = 50000;
	uint256 public constant PRICE_ICO1 = 33333;
	uint256 public constant PRICE_ICO2 = 25000;
	uint256 public constant PRICE_ICO4 = 20000;
	
	uint256 public constant delayOfPreICO = blocksByDay*23;
	uint256 public constant delayOfICO1 = blocksByDay*46;
	uint256 public constant delayOfICO2 = blocksByDay*69;
	uint256 public constant delayOfICOEND = blocksByDay*90;
   uint256 public constant minimumGoal = coinMultiplayer*(10**6)*178 ;
  uint256 public constant maxTokenSupplyPreICO = coinMultiplayer*(10**6)*357 ; 
  uint256 public constant maxTokenSupplyICO1 = coinMultiplayer*(10**6)*595 ; 
  uint256 public constant maxTokenSupplyICO2 = coinMultiplayer*(10**6)*833 ; 
  uint256 public constant maxTokenSupplyICOEND =coinMultiplayer*(10**6)*1000 ; 
}


library SafeMath {
  function mul(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant public returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) constant public returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}

contract DevTeamContractI{
	function recieveFunds() payable public;
}

contract CABCoinI{
  address public owner;
  uint256 public totalSupply;
  bool public mintingFinished = false;
  modifier onlyOwner() {
    if(msg.sender == owner){
      _;
    }
    else{
      revert();
    }
  }
  
  modifier canMint() {
    if(!mintingFinished){
      _;
    }
    else{
      revert();
    }
  }
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool);
  function getMaxTokenAvaliable() constant public  returns(uint256);
  function finishMinting() onlyOwner public returns (bool);
}

contract CABCoinICO is Constants{
  using SafeMath for uint256;
  mapping(address =&gt; bool) public preICOHolders ;
  mapping(address =&gt; uint256) public ethGiven ;
	address public tokenAddress = 0;
	DevTeamContractI public devTeam;
	uint256 public _startBlock ;
	CABCoinI public coin;
	
	
	event AmountToLittle();
	event SendAllFunds();
	event Buy(address who,uint256 amount);
	event Refund(address who,uint256 amount);
	
  modifier canMint() {
    if(coin.mintingFinished()==false){
    	_;
    }
    else{
    	
    }
  }
  
  bool private isRunned = false;
  
  modifier runOnce() {
  	if(isRunned){
  		revert();
  	}
  	else{
  		isRunned = true;
  		_;
  	}
  }
  
	uint256 public currBlock = 1;
	
	function GetTime() public constant returns(uint256) {
	  return block.number;
	}
	
	function getAllTimes() public constant returns(uint256,uint256,uint256){
		if(GetTime()&lt;_startBlock){
			return(_startBlock.sub(GetTime()),0,0);
		}
		if(GetTime()&lt;=_startBlock.add(delayOfICOEND))
		{
			uint256 currentStageTime = 0;
			if(GetTime()&lt;_startBlock.add(delayOfPreICO)){
				currentStageTime = _startBlock.add(delayOfPreICO) - GetTime();
			}
			else{
				if(GetTime()&lt;_startBlock.add(delayOfICO1)){
					currentStageTime = _startBlock.add(delayOfICO1) - GetTime();
				}
				else{
					if(GetTime()&lt;_startBlock.add(delayOfICO2)){
						currentStageTime = _startBlock.add(delayOfICO2) - GetTime();
					}
				}
			}
			if(GetTime()&gt;=_startBlock){
				return(0,currentStageTime,_startBlock.add(delayOfICOEND)-GetTime());
			}
		}
		else{
			return(0,0,0);
		}
	}
	
	function CABCoinICO(uint256 sBlock) public {
		if(sBlock==0){
	    	_startBlock = GetTime();
		}
		else{
	    	_startBlock = sBlock;
		}
	}
	
	function SetContracts(address coinAdr, address dev) runOnce() public{
		
  		if(tokenAddress == address(0)){
  			tokenAddress = coinAdr;
		    coin = CABCoinI(coinAdr);
		    devTeam =  DevTeamContractI(dev);
  		}
	}
	
	function getMaxEther() constant public  returns(uint256) {
		uint256 maxAv = coin.getMaxTokenAvaliable();
		uint256 price = getCabCoinsAmount();
		var maxEth = maxAv.div(price);
		return maxEth;
	}
	
	function isAfterICO()  public constant returns(bool) {
	  return (getCabCoinsAmount() == 0); 
	}
	
	function getCabCoinsAmount()  public constant returns(uint256) {
		if(GetTime()&lt;_startBlock){
			return 0;	
		}
	    if(GetTime()&lt;_startBlock.add(delayOfPreICO)){
	    	if(maxTokenSupplyPreICO&gt;coin.totalSupply()){
	        	return PRICE_PREICO;
	    	}
	    }
	    if(GetTime()&lt;_startBlock.add(delayOfICO1) ){
		    if(maxTokenSupplyICO1&gt;coin.totalSupply()){
		        return PRICE_ICO1;
		    }	
	    } 
	    if(GetTime()&lt;_startBlock.add(delayOfICO2)){
	    	if(maxTokenSupplyICO2&gt;coin.totalSupply()){
	        	return PRICE_ICO2;
	    	}
	    }
	    if(GetTime()&lt;=_startBlock.add(delayOfICOEND)){
	    	if(maxTokenSupplyICOEND&gt;=coin.totalSupply()){
	        	return PRICE_ICO4;
	    	}
	    }
		return 0; 
	}
	
	function() payable public{
		
	  if(isAfterICO() &amp;&amp; coin.totalSupply()&lt;minimumGoal){
		this.refund.value(msg.value)(msg.sender);
	  }else{
	  	if(msg.value==0){
	  		sendAllFunds();
	  	}else{
	  		
		  	if(isAfterICO() == false){
				this.buy.value(msg.value)(msg.sender);
		  	}else{
	  			revert();	
		  	}
	  	}
	  }
	}
	
	function buy(address owner) payable public{
		
	  bool isMintedDev ;
	  bool isMinted ;
	  Buy(owner,msg.value);
	  uint256 tokensAmountPerEth = getCabCoinsAmount();
	  
		if(GetTime()&lt;_startBlock){
			revert();
		}
		else{
			
			if(tokensAmountPerEth==0){
			  coin.finishMinting();
			  msg.sender.transfer(msg.value);
			}
			else{
			
				uint256 tokensAvailable = coin.getMaxTokenAvaliable() ;
		  		uint256 val = tokensAmountPerEth.mul(msg.value) ;
		  		
		  		uint256 valForTeam = val.mul(TEAM_SHARE_PERCENTAGE).div(100-TEAM_SHARE_PERCENTAGE);
		  		
		  		if(tokensAvailable&lt;val+valForTeam){
		  			AmountToLittle();
		  			val = val.mul(tokensAvailable).div(val.add(valForTeam));
		  			valForTeam = val.mul(TEAM_SHARE_PERCENTAGE).div(100-TEAM_SHARE_PERCENTAGE);
			  		isMintedDev =coin.mint(owner,val);
			  		isMinted =  coin.mint(devTeam,valForTeam);
			  		
			     	ethGiven[owner] = ethGiven[owner].add(msg.value);
			  		if(isMintedDev==false){
			  		  revert();
			  		}
			  		if(isMinted==false){
			  		  revert();
			  		}
					coin.finishMinting();
		  		}
		  		else
		  		{
		  			
			  		if(IsPreICO()){
			  		  preICOHolders[owner] = true;
			  		  devTeam.recieveFunds.value(msg.value.mul(PRE_ICO_RISK_PERCENTAGE).div(100))();
			  		}
			  	
			  		isMintedDev =coin.mint(owner,val);
			  		isMinted =  coin.mint(devTeam,valForTeam);
			  		
			     	ethGiven[owner] = ethGiven[owner].add(msg.value);
			  		if(isMintedDev==false){
			  		  revert();
			  		}
			  		if(isMinted==false){
			  		  revert();
			  		}
			  		
		  		}
			
			}
		 
		}
		
	}
	
	function IsPreICO() returns(bool){
	  if(GetTime()&lt;_startBlock.add(delayOfPreICO)){
	    return true;
	  }
	  else{
	    return false;
	  }
	}
	
	function sendAllFunds() public {
	  SendAllFunds();
	  if(coin.totalSupply()&gt;=minimumGoal){ // goal reached money Goes to devTeam
	    
		devTeam.recieveFunds.value(this.balance)();
	  }
	  else
	  {
	    revert();
	  }
	}
	
	
	function refund(address sender) payable public {
	  Refund(sender,ethGiven[sender]);
	  if(isAfterICO() &amp;&amp; coin.totalSupply()&lt;minimumGoal){ // goal not reached
	    var sumToReturn = ethGiven[sender];
	     ethGiven[sender] =0;
	    if(preICOHolders[msg.sender]){
	    	sumToReturn = sumToReturn.mul(100-PRE_ICO_RISK_PERCENTAGE).div(100);
	    }
	    sumToReturn = sumToReturn.add(msg.value);
	    if(sumToReturn&gt;this.balance){
	    	sender.transfer(this.balance);
	    }
	    else{
	    	sender.transfer(sumToReturn.add(msg.value));
	    }
	  }
	  else
	  {
	  	if(msg.value&gt;0){
	  		sender.transfer(msg.value);
	  	}
	  }
	}
}