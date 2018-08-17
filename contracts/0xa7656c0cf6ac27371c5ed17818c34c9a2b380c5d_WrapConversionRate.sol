pragma solidity 0.4.18;

// File: ../../wrapConvRate/smart-contracts/contracts/ERC20Interface.sol

// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: ../../wrapConvRate/smart-contracts/contracts/ConversionRatesInterface.sol

contract ConversionRatesInterface {

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public;

    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint);
}

// File: ../../wrapConvRate/smart-contracts/contracts/Utils.sol

/// @title Kyber constants contract
contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28); // 10B tokens
    uint  constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;
    mapping(address=&gt;uint) internal decimals;

    function setDecimals(ERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS) decimals[token] = ETH_DECIMALS;
        else decimals[token] = token.decimals();
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint tokenDecimals = decimals[token];
        // technically, there might be token with decimals 0
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if(tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty &lt;= MAX_QTY);
        require(rate &lt;= MAX_RATE);

        if (dstDecimals &gt;= srcDecimals) {
            require((dstDecimals - srcDecimals) &lt;= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) &lt;= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty &lt;= MAX_QTY);
        require(rate &lt;= MAX_RATE);
        
        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals &gt;= dstDecimals) {
            require((srcDecimals - dstDecimals) &lt;= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) &lt;= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }
}

// File: ../../wrapConvRate/smart-contracts/contracts/PermissionGroups.sol

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=&gt;bool) internal operators;
    mapping(address=&gt;bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    function PermissionGroups() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(newAdmin);
        AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length &lt; MAX_GROUP_SIZE);

        AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i &lt; alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length &lt; MAX_GROUP_SIZE);

        OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i &lt; operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// File: ../../wrapConvRate/smart-contracts/contracts/Withdrawable.sol

/**
 * @title Contracts that should be able to recover tokens or ethers
 * @author Ilan Doron
 * @dev This allows to recover any tokens or Ethers received in a contract.
 * This will prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }
}

// File: ../../wrapConvRate/smart-contracts/contracts/VolumeImbalanceRecorder.sol

contract VolumeImbalanceRecorder is Withdrawable {

    uint constant internal SLIDING_WINDOW_SIZE = 5;
    uint constant internal POW_2_64 = 2 ** 64;

    struct TokenControlInfo {
        uint minimalRecordResolution; // can be roughly 1 cent
        uint maxPerBlockImbalance; // in twei resolution
        uint maxTotalImbalance; // max total imbalance (between rate updates)
                            // before halting trade
    }

    mapping(address =&gt; TokenControlInfo) internal tokenControlInfo;

    struct TokenImbalanceData {
        int  lastBlockBuyUnitsImbalance;
        uint lastBlock;

        int  totalBuyUnitsImbalance;
        uint lastRateUpdateBlock;
    }

    mapping(address =&gt; mapping(uint=&gt;uint)) public tokenImbalanceData;

    function VolumeImbalanceRecorder(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    function setTokenControlInfo(
        ERC20 token,
        uint minimalRecordResolution,
        uint maxPerBlockImbalance,
        uint maxTotalImbalance
    )
        public
        onlyAdmin
    {
        tokenControlInfo[token] =
            TokenControlInfo(
                minimalRecordResolution,
                maxPerBlockImbalance,
                maxTotalImbalance
            );
    }

    function getTokenControlInfo(ERC20 token) public view returns(uint, uint, uint) {
        return (tokenControlInfo[token].minimalRecordResolution,
                tokenControlInfo[token].maxPerBlockImbalance,
                tokenControlInfo[token].maxTotalImbalance);
    }

    function addImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        internal
    {
        uint currentBlockIndex = currentBlock % SLIDING_WINDOW_SIZE;
        int recordedBuyAmount = int(buyAmount / int(tokenControlInfo[token].minimalRecordResolution));

        int prevImbalance = 0;

        TokenImbalanceData memory currentBlockData =
            decodeTokenImbalanceData(tokenImbalanceData[token][currentBlockIndex]);

        // first scenario - this is not the first tx in the current block
        if (currentBlockData.lastBlock == currentBlock) {
            if (uint(currentBlockData.lastRateUpdateBlock) == rateUpdateBlock) {
                // just increase imbalance
                currentBlockData.lastBlockBuyUnitsImbalance += recordedBuyAmount;
                currentBlockData.totalBuyUnitsImbalance += recordedBuyAmount;
            } else {
                // imbalance was changed in the middle of the block
                prevImbalance = getImbalanceInRange(token, rateUpdateBlock, currentBlock);
                currentBlockData.totalBuyUnitsImbalance = int(prevImbalance) + recordedBuyAmount;
                currentBlockData.lastBlockBuyUnitsImbalance += recordedBuyAmount;
                currentBlockData.lastRateUpdateBlock = uint(rateUpdateBlock);
            }
        } else {
            // first tx in the current block
            int currentBlockImbalance;
            (prevImbalance, currentBlockImbalance) = getImbalanceSinceRateUpdate(token, rateUpdateBlock, currentBlock);

            currentBlockData.lastBlockBuyUnitsImbalance = recordedBuyAmount;
            currentBlockData.lastBlock = uint(currentBlock);
            currentBlockData.lastRateUpdateBlock = uint(rateUpdateBlock);
            currentBlockData.totalBuyUnitsImbalance = int(prevImbalance) + recordedBuyAmount;
        }

        tokenImbalanceData[token][currentBlockIndex] = encodeTokenImbalanceData(currentBlockData);
    }

    function setGarbageToVolumeRecorder(ERC20 token) internal {
        for (uint i = 0; i &lt; SLIDING_WINDOW_SIZE; i++) {
            tokenImbalanceData[token][i] = 0x1;
        }
    }

    function getImbalanceInRange(ERC20 token, uint startBlock, uint endBlock) internal view returns(int buyImbalance) {
        // check the imbalance in the sliding window
        require(startBlock &lt;= endBlock);

        buyImbalance = 0;

        for (uint windowInd = 0; windowInd &lt; SLIDING_WINDOW_SIZE; windowInd++) {
            TokenImbalanceData memory perBlockData = decodeTokenImbalanceData(tokenImbalanceData[token][windowInd]);

            if (perBlockData.lastBlock &lt;= endBlock &amp;&amp; perBlockData.lastBlock &gt;= startBlock) {
                buyImbalance += int(perBlockData.lastBlockBuyUnitsImbalance);
            }
        }
    }

    function getImbalanceSinceRateUpdate(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int buyImbalance, int currentBlockImbalance)
    {
        buyImbalance = 0;
        currentBlockImbalance = 0;
        uint latestBlock = 0;
        int imbalanceInRange = 0;
        uint startBlock = rateUpdateBlock;
        uint endBlock = currentBlock;

        for (uint windowInd = 0; windowInd &lt; SLIDING_WINDOW_SIZE; windowInd++) {
            TokenImbalanceData memory perBlockData = decodeTokenImbalanceData(tokenImbalanceData[token][windowInd]);

            if (perBlockData.lastBlock &lt;= endBlock &amp;&amp; perBlockData.lastBlock &gt;= startBlock) {
                imbalanceInRange += perBlockData.lastBlockBuyUnitsImbalance;
            }

            if (perBlockData.lastRateUpdateBlock != rateUpdateBlock) continue;
            if (perBlockData.lastBlock &lt; latestBlock) continue;

            latestBlock = perBlockData.lastBlock;
            buyImbalance = perBlockData.totalBuyUnitsImbalance;
            if (uint(perBlockData.lastBlock) == currentBlock) {
                currentBlockImbalance = perBlockData.lastBlockBuyUnitsImbalance;
            }
        }

        if (buyImbalance == 0) {
            buyImbalance = imbalanceInRange;
        }
    }

    function getImbalance(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int totalImbalance, int currentBlockImbalance)
    {

        int resolution = int(tokenControlInfo[token].minimalRecordResolution);

        (totalImbalance, currentBlockImbalance) =
            getImbalanceSinceRateUpdate(
                token,
                rateUpdateBlock,
                currentBlock);

        totalImbalance *= resolution;
        currentBlockImbalance *= resolution;
    }

    function getMaxPerBlockImbalance(ERC20 token) internal view returns(uint) {
        return tokenControlInfo[token].maxPerBlockImbalance;
    }

    function getMaxTotalImbalance(ERC20 token) internal view returns(uint) {
        return tokenControlInfo[token].maxTotalImbalance;
    }

    function encodeTokenImbalanceData(TokenImbalanceData data) internal pure returns(uint) {
        // check for overflows
        require(data.lastBlockBuyUnitsImbalance &lt; int(POW_2_64 / 2));
        require(data.lastBlockBuyUnitsImbalance &gt; int(-1 * int(POW_2_64) / 2));
        require(data.lastBlock &lt; POW_2_64);
        require(data.totalBuyUnitsImbalance &lt; int(POW_2_64 / 2));
        require(data.totalBuyUnitsImbalance &gt; int(-1 * int(POW_2_64) / 2));
        require(data.lastRateUpdateBlock &lt; POW_2_64);

        // do encoding
        uint result = uint(data.lastBlockBuyUnitsImbalance) &amp; (POW_2_64 - 1);
        result |= data.lastBlock * POW_2_64;
        result |= (uint(data.totalBuyUnitsImbalance) &amp; (POW_2_64 - 1)) * POW_2_64 * POW_2_64;
        result |= data.lastRateUpdateBlock * POW_2_64 * POW_2_64 * POW_2_64;

        return result;
    }

    function decodeTokenImbalanceData(uint input) internal pure returns(TokenImbalanceData) {
        TokenImbalanceData memory data;

        data.lastBlockBuyUnitsImbalance = int(int64(input &amp; (POW_2_64 - 1)));
        data.lastBlock = uint(uint64((input / POW_2_64) &amp; (POW_2_64 - 1)));
        data.totalBuyUnitsImbalance = int(int64((input / (POW_2_64 * POW_2_64)) &amp; (POW_2_64 - 1)));
        data.lastRateUpdateBlock = uint(uint64((input / (POW_2_64 * POW_2_64 * POW_2_64))));

        return data;
    }
}

// File: ../../wrapConvRate/smart-contracts/contracts/ConversionRates.sol

contract ConversionRates is ConversionRatesInterface, VolumeImbalanceRecorder, Utils {

    // bps - basic rate steps. one step is 1 / 10000 of the rate.
    struct StepFunction {
        int[] x; // quantity for each step. Quantity of each step includes previous steps.
        int[] y; // rate change per quantity step  in bps.
    }

    struct TokenData {
        bool listed;  // was added to reserve
        bool enabled; // whether trade is enabled

        // position in the compact data
        uint compactDataArrayIndex;
        uint compactDataFieldIndex;

        // rate data. base and changes according to quantity and reserve balance.
        // generally speaking. Sell rate is 1 / buy rate i.e. the buy in the other direction.
        uint baseBuyRate;  // in PRECISION units. see KyberConstants
        uint baseSellRate; // PRECISION units. without (sell / buy) spread it is 1 / baseBuyRate
        StepFunction buyRateQtyStepFunction; // in bps. higher quantity - bigger the rate.
        StepFunction sellRateQtyStepFunction;// in bps. higher the qua
        StepFunction buyRateImbalanceStepFunction; // in BPS. higher reserve imbalance - bigger the rate.
        StepFunction sellRateImbalanceStepFunction;
    }

    /*
    this is the data for tokenRatesCompactData
    but solidity compiler optimizer is sub-optimal, and cannot write this structure in a single storage write
    so we represent it as bytes32 and do the byte tricks ourselves.
    struct TokenRatesCompactData {
        bytes14 buy;  // change buy rate of token from baseBuyRate in 10 bps
        bytes14 sell; // change sell rate of token from baseSellRate in 10 bps

        uint32 blockNumber;
    } */
    uint public validRateDurationInBlocks = 10; // rates are valid for this amount of blocks
    ERC20[] internal listedTokens;
    mapping(address=&gt;TokenData) internal tokenData;
    bytes32[] internal tokenRatesCompactData;
    uint public numTokensInCurrentCompactData = 0;
    address public reserveContract;
    uint constant internal NUM_TOKENS_IN_COMPACT_DATA = 14;
    uint constant internal BYTES_14_OFFSET = (2 ** (8 * NUM_TOKENS_IN_COMPACT_DATA));
    uint constant internal MAX_STEPS_IN_FUNCTION = 10;
    int  constant internal MAX_BPS_ADJUSTMENT = 10 ** 11; // 1B %
    int  constant internal MIN_BPS_ADJUSTMENT = -100 * 100; // cannot go down by more than 100%

    function ConversionRates(address _admin) public VolumeImbalanceRecorder(_admin)
        { } // solhint-disable-line no-empty-blocks

    function addToken(ERC20 token) public onlyAdmin {

        require(!tokenData[token].listed);
        tokenData[token].listed = true;
        listedTokens.push(token);

        if (numTokensInCurrentCompactData == 0) {
            tokenRatesCompactData.length++; // add new structure
        }

        tokenData[token].compactDataArrayIndex = tokenRatesCompactData.length - 1;
        tokenData[token].compactDataFieldIndex = numTokensInCurrentCompactData;

        numTokensInCurrentCompactData = (numTokensInCurrentCompactData + 1) % NUM_TOKENS_IN_COMPACT_DATA;

        setGarbageToVolumeRecorder(token);

        setDecimals(token);
    }

    function setCompactData(bytes14[] buy, bytes14[] sell, uint blockNumber, uint[] indices) public onlyOperator {

        require(buy.length == sell.length);
        require(indices.length == buy.length);
        require(blockNumber &lt;= 0xFFFFFFFF);

        uint bytes14Offset = BYTES_14_OFFSET;

        for (uint i = 0; i &lt; indices.length; i++) {
            require(indices[i] &lt; tokenRatesCompactData.length);
            uint data = uint(buy[i]) | uint(sell[i]) * bytes14Offset | (blockNumber * (bytes14Offset * bytes14Offset));
            tokenRatesCompactData[indices[i]] = bytes32(data);
        }
    }

    function setBaseRate(
        ERC20[] tokens,
        uint[] baseBuy,
        uint[] baseSell,
        bytes14[] buy,
        bytes14[] sell,
        uint blockNumber,
        uint[] indices
    )
        public
        onlyOperator
    {
        require(tokens.length == baseBuy.length);
        require(tokens.length == baseSell.length);
        require(sell.length == buy.length);
        require(sell.length == indices.length);

        for (uint ind = 0; ind &lt; tokens.length; ind++) {
            require(tokenData[tokens[ind]].listed);
            tokenData[tokens[ind]].baseBuyRate = baseBuy[ind];
            tokenData[tokens[ind]].baseSellRate = baseSell[ind];
        }

        setCompactData(buy, sell, blockNumber, indices);
    }

    function setQtyStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length == yBuy.length);
        require(xSell.length == ySell.length);
        require(xBuy.length &lt;= MAX_STEPS_IN_FUNCTION);
        require(xSell.length &lt;= MAX_STEPS_IN_FUNCTION);
        require(tokenData[token].listed);

        tokenData[token].buyRateQtyStepFunction = StepFunction(xBuy, yBuy);
        tokenData[token].sellRateQtyStepFunction = StepFunction(xSell, ySell);
    }

    function setImbalanceStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length == yBuy.length);
        require(xSell.length == ySell.length);
        require(xBuy.length &lt;= MAX_STEPS_IN_FUNCTION);
        require(xSell.length &lt;= MAX_STEPS_IN_FUNCTION);
        require(tokenData[token].listed);

        tokenData[token].buyRateImbalanceStepFunction = StepFunction(xBuy, yBuy);
        tokenData[token].sellRateImbalanceStepFunction = StepFunction(xSell, ySell);
    }

    function setValidRateDurationInBlocks(uint duration) public onlyAdmin {
        validRateDurationInBlocks = duration;
    }

    function enableTokenTrade(ERC20 token) public onlyAdmin {
        require(tokenData[token].listed);
        require(tokenControlInfo[token].minimalRecordResolution != 0);
        tokenData[token].enabled = true;
    }

    function disableTokenTrade(ERC20 token) public onlyAlerter {
        require(tokenData[token].listed);
        tokenData[token].enabled = false;
    }

    function setReserveAddress(address reserve) public onlyAdmin {
        reserveContract = reserve;
    }

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public
    {
        require(msg.sender == reserveContract);

        if (rateUpdateBlock == 0) rateUpdateBlock = getRateUpdateBlock(token);

        return addImbalance(token, buyAmount, rateUpdateBlock, currentBlock);
    }

    /* solhint-disable function-max-lines */
    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint) {
        // check if trade is enabled
        if (!tokenData[token].enabled) return 0;
        if (tokenControlInfo[token].minimalRecordResolution == 0) return 0; // token control info not set

        // get rate update block
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];

        uint updateRateBlock = getLast4Bytes(compactData);
        if (currentBlockNumber &gt;= updateRateBlock + validRateDurationInBlocks) return 0; // rate is expired
        // check imbalance
        int totalImbalance;
        int blockImbalance;
        (totalImbalance, blockImbalance) = getImbalance(token, updateRateBlock, currentBlockNumber);

        // calculate actual rate
        int imbalanceQty;
        int extraBps;
        int8 rateUpdate;
        uint rate;

        if (buy) {
            // start with base rate
            rate = tokenData[token].baseBuyRate;

            // add rate update
            rateUpdate = getRateByteFromCompactData(compactData, token, true);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

            // compute token qty
            qty = getTokenQty(token, rate, qty);
            imbalanceQty = int(qty);
            totalImbalance += imbalanceQty;

            // add qty overhead
            extraBps = executeStepFunction(tokenData[token].buyRateQtyStepFunction, int(qty));
            rate = addBps(rate, extraBps);

            // add imbalance overhead
            extraBps = executeStepFunction(tokenData[token].buyRateImbalanceStepFunction, totalImbalance);
            rate = addBps(rate, extraBps);
        } else {
            // start with base rate
            rate = tokenData[token].baseSellRate;

            // add rate update
            rateUpdate = getRateByteFromCompactData(compactData, token, false);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

            // compute token qty
            imbalanceQty = -1 * int(qty);
            totalImbalance += imbalanceQty;

            // add qty overhead
            extraBps = executeStepFunction(tokenData[token].sellRateQtyStepFunction, int(qty));
            rate = addBps(rate, extraBps);

            // add imbalance overhead
            extraBps = executeStepFunction(tokenData[token].sellRateImbalanceStepFunction, totalImbalance);
            rate = addBps(rate, extraBps);
        }

        if (abs(totalImbalance) &gt;= getMaxTotalImbalance(token)) return 0;
        if (abs(blockImbalance + imbalanceQty) &gt;= getMaxPerBlockImbalance(token)) return 0;

        return rate;
    }
    /* solhint-enable function-max-lines */

    function getBasicRate(ERC20 token, bool buy) public view returns(uint) {
        if (buy)
            return tokenData[token].baseBuyRate;
        else
            return tokenData[token].baseSellRate;
    }

    function getCompactData(ERC20 token) public view returns(uint, uint, byte, byte) {
        require(tokenData[token].listed);

        uint arrayIndex = tokenData[token].compactDataArrayIndex;
        uint fieldOffset = tokenData[token].compactDataFieldIndex;

        return (
            arrayIndex,
            fieldOffset,
            byte(getRateByteFromCompactData(tokenRatesCompactData[arrayIndex], token, true)),
            byte(getRateByteFromCompactData(tokenRatesCompactData[arrayIndex], token, false))
        );
    }

    function getTokenBasicData(ERC20 token) public view returns(bool, bool) {
        return (tokenData[token].listed, tokenData[token].enabled);
    }

    /* solhint-disable code-complexity */
    function getStepFunctionData(ERC20 token, uint command, uint param) public view returns(int) {
        if (command == 0) return int(tokenData[token].buyRateQtyStepFunction.x.length);
        if (command == 1) return tokenData[token].buyRateQtyStepFunction.x[param];
        if (command == 2) return int(tokenData[token].buyRateQtyStepFunction.y.length);
        if (command == 3) return tokenData[token].buyRateQtyStepFunction.y[param];

        if (command == 4) return int(tokenData[token].sellRateQtyStepFunction.x.length);
        if (command == 5) return tokenData[token].sellRateQtyStepFunction.x[param];
        if (command == 6) return int(tokenData[token].sellRateQtyStepFunction.y.length);
        if (command == 7) return tokenData[token].sellRateQtyStepFunction.y[param];

        if (command == 8) return int(tokenData[token].buyRateImbalanceStepFunction.x.length);
        if (command == 9) return tokenData[token].buyRateImbalanceStepFunction.x[param];
        if (command == 10) return int(tokenData[token].buyRateImbalanceStepFunction.y.length);
        if (command == 11) return tokenData[token].buyRateImbalanceStepFunction.y[param];

        if (command == 12) return int(tokenData[token].sellRateImbalanceStepFunction.x.length);
        if (command == 13) return tokenData[token].sellRateImbalanceStepFunction.x[param];
        if (command == 14) return int(tokenData[token].sellRateImbalanceStepFunction.y.length);
        if (command == 15) return tokenData[token].sellRateImbalanceStepFunction.y[param];

        revert();
    }
    /* solhint-enable code-complexity */

    function getRateUpdateBlock(ERC20 token) public view returns(uint) {
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];
        return getLast4Bytes(compactData);
    }

    function getListedTokens() public view returns(ERC20[]) {
        return listedTokens;
    }

    function getTokenQty(ERC20 token, uint ethQty, uint rate) internal view returns(uint) {
        uint dstDecimals = getDecimals(token);
        uint srcDecimals = ETH_DECIMALS;

        return calcDstQty(ethQty, srcDecimals, dstDecimals, rate);
    }

    function getLast4Bytes(bytes32 b) internal pure returns(uint) {
        // cannot trust compiler with not turning bit operations into EXP opcode
        return uint(b) / (BYTES_14_OFFSET * BYTES_14_OFFSET);
    }

    function getRateByteFromCompactData(bytes32 data, ERC20 token, bool buy) internal view returns(int8) {
        uint fieldOffset = tokenData[token].compactDataFieldIndex;
        uint byteOffset;
        if (buy)
            byteOffset = 32 - NUM_TOKENS_IN_COMPACT_DATA + fieldOffset;
        else
            byteOffset = 4 + fieldOffset;

        return int8(data[byteOffset]);
    }

    function executeStepFunction(StepFunction f, int x) internal pure returns(int) {
        uint len = f.y.length;
        for (uint ind = 0; ind &lt; len; ind++) {
            if (x &lt;= f.x[ind]) return f.y[ind];
        }

        return f.y[len-1];
    }

    function addBps(uint rate, int bps) internal pure returns(uint) {
        require(rate &lt;= MAX_RATE);
        require(bps &gt;= MIN_BPS_ADJUSTMENT);
        require(bps &lt;= MAX_BPS_ADJUSTMENT);

        uint maxBps = 100 * 100;
        return (rate * uint(int(maxBps) + bps)) / maxBps;
    }

    function abs(int x) internal pure returns(uint) {
        if (x &lt; 0)
            return uint(-1 * x);
        else
            return uint(x);
    }
}

// File: ../../wrapConvRate/smart-contracts/contracts/wrapperContracts/WrapperBase.sol

contract WrapperBase is Withdrawable {

    PermissionGroups public wrappedContract;

    struct DataTracker {
        address [] approveSignatureArray;
        uint lastSetNonce;
    }

    DataTracker[] internal dataInstances;

    function WrapperBase(PermissionGroups _wrappedContract, address _admin, uint _numDataInstances) public {
        require(_wrappedContract != address(0));
        require(_admin != address(0));
        wrappedContract = _wrappedContract;
        admin = _admin;

        for (uint i = 0; i &lt; _numDataInstances; i++){
            addDataInstance();
        }
    }

    function claimWrappedContractAdmin() public onlyOperator {
        wrappedContract.claimAdmin();
    }

    function transferWrappedContractAdmin (address newAdmin) public onlyAdmin {
        wrappedContract.transferAdmin(newAdmin);
    }

    function addDataInstance() internal {
        address[] memory add = new address[](0);
        dataInstances.push(DataTracker(add, 0));
    }

    function setNewData(uint dataIndex) internal {
        require(dataIndex &lt; dataInstances.length);
        dataInstances[dataIndex].lastSetNonce++;
        dataInstances[dataIndex].approveSignatureArray.length = 0;
    }

    function addSignature(uint dataIndex, uint signedNonce, address signer) internal returns(bool allSigned) {
        require(dataIndex &lt; dataInstances.length);
        require(dataInstances[dataIndex].lastSetNonce == signedNonce);

        for(uint i = 0; i &lt; dataInstances[dataIndex].approveSignatureArray.length; i++) {
            if (signer == dataInstances[dataIndex].approveSignatureArray[i]) revert();
        }
        dataInstances[dataIndex].approveSignatureArray.push(signer);

        if (dataInstances[dataIndex].approveSignatureArray.length == operatorsGroup.length) {
            allSigned = true;
        } else {
            allSigned = false;
        }
    }

    function getDataTrackingParameters(uint index) internal view returns (address[], uint) {
        require(index &lt; dataInstances.length);
        return(dataInstances[index].approveSignatureArray, dataInstances[index].lastSetNonce);
    }
}

// File: ../../wrapConvRate/smart-contracts/contracts/wrapperContracts/WrapConversionRate.sol

contract WrapConversionRate is WrapperBase {

    ConversionRates internal conversionRates;

    //add token parameters
    struct AddTokenData {
        ERC20     token;
        uint      minimalResolution; // can be roughly 1 cent
        uint      maxPerBlockImbalance; // in twei resolution
        uint      maxTotalImbalance;
    }

    AddTokenData internal addTokenData;

    //set token control info parameters.
    struct TokenControlInfoData {
        ERC20[] tokens;
        uint[] perBlockImbalance; // in twei resolution
        uint[] maxTotalImbalance;
    }

    TokenControlInfoData internal tokenControlInfoData;

    //valid duration
    struct ValidDurationData {
        uint durationInBlocks;
    }

    ValidDurationData internal validDurationData;

    //data indexes
    uint constant internal ADD_TOKEN_DATA_INDEX = 0;
    uint constant internal TOKEN_INFO_DATA_INDEX = 1;
    uint constant internal VALID_DURATION_DATA_INDEX = 2;
    uint constant internal NUM_DATA_INDEX = 3;

    //general functions
    function WrapConversionRate(ConversionRates _conversionRates, address _admin) public
        WrapperBase(PermissionGroups(address(_conversionRates)), _admin, NUM_DATA_INDEX)
    {
        require(_conversionRates != address(0));
        conversionRates = _conversionRates;
    }

    // add token functions
    //////////////////////
    function setAddTokenData(
        ERC20 token,
        uint minRecordResolution,
        uint maxPerBlockImbalance,
        uint maxTotalImbalance
        ) public onlyOperator
    {
        require(token != address(0));
        require(minRecordResolution != 0);
        require(maxPerBlockImbalance != 0);
        require(maxTotalImbalance != 0);

        //update data tracking
        setNewData(ADD_TOKEN_DATA_INDEX);

        addTokenData.token = token;
        addTokenData.minimalResolution = minRecordResolution; // can be roughly 1 cent
        addTokenData.maxPerBlockImbalance = maxPerBlockImbalance; // in twei resolution
        addTokenData.maxTotalImbalance = maxTotalImbalance;
    }

    function approveAddTokenData(uint nonce) public onlyOperator {
        if (addSignature(ADD_TOKEN_DATA_INDEX, nonce, msg.sender)) {
            // can perform operation.
            performAddToken();
        }
    }

    function getAddTokenData() public view
        returns(uint nonce, ERC20 token, uint minRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance)
    {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(ADD_TOKEN_DATA_INDEX);
        token = addTokenData.token;
        minRecordResolution = addTokenData.minimalResolution;
        maxPerBlockImbalance = addTokenData.maxPerBlockImbalance; // in twei resolution
        maxTotalImbalance = addTokenData.maxTotalImbalance;
        return(nonce, token, minRecordResolution, maxPerBlockImbalance, maxTotalImbalance);
    }

    function getAddTokenSignatures() public view returns (address[] memory signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(ADD_TOKEN_DATA_INDEX);
        return(signatures);
    }

    //set token control info
    ////////////////////////
    function setTokenInfoData(ERC20[] tokens, uint[] maxPerBlockImbalanceValues, uint[] maxTotalImbalanceValues)
        public
        onlyOperator
    {
        require(maxPerBlockImbalanceValues.length == tokens.length);
        require(maxTotalImbalanceValues.length == tokens.length);

        //update data tracking
        setNewData(TOKEN_INFO_DATA_INDEX);

        tokenControlInfoData.tokens = tokens;
        tokenControlInfoData.perBlockImbalance = maxPerBlockImbalanceValues;
        tokenControlInfoData.maxTotalImbalance = maxTotalImbalanceValues;
    }

    function approveTokenControlInfo(uint nonce) public onlyOperator {
        if (addSignature(TOKEN_INFO_DATA_INDEX, nonce, msg.sender)) {
            // can perform operation.
            performSetTokenControlInfo();
        }
    }

    function getControlInfoPerToken (uint index) public view
        returns(ERC20 token, uint _maxPerBlockImbalance, uint _maxTotalImbalance, uint nonce)
    {
        require(tokenControlInfoData.tokens.length &gt; index);
        require(tokenControlInfoData.perBlockImbalance.length &gt; index);
        require(tokenControlInfoData.maxTotalImbalance.length &gt; index);
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(TOKEN_INFO_DATA_INDEX);

        return(
            tokenControlInfoData.tokens[index],
            tokenControlInfoData.perBlockImbalance[index],
            tokenControlInfoData.maxTotalImbalance[index],
            nonce
        );
    }

    function getTokenInfoNumToknes() public view returns(uint numSetTokens) {
        return tokenControlInfoData.tokens.length;
    }

    function getTokenInfoData() public view
        returns(uint nonce, uint numSetTokens, ERC20[] tokenAddress, uint[] maxPerBlock, uint[] maxTotal)
    {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(TOKEN_INFO_DATA_INDEX);

        return(
            nonce,
            tokenControlInfoData.tokens.length,
            tokenControlInfoData.tokens,
            tokenControlInfoData.perBlockImbalance,
            tokenControlInfoData.maxTotalImbalance);
    }

    function getTokenInfoSignatures() public view returns (address[] memory signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(TOKEN_INFO_DATA_INDEX);
        return(signatures);
    }

    function getTokenInfoNonce() public view returns(uint nonce) {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(TOKEN_INFO_DATA_INDEX);
        return nonce;
    }

    //valid duration blocks
    ///////////////////////
    function setValidDurationData(uint validDurationBlocks) public onlyOperator {
        require(validDurationBlocks &gt; 5);

        //update data tracking
        setNewData(VALID_DURATION_DATA_INDEX);

        validDurationData.durationInBlocks = validDurationBlocks;
    }

    function approveValidDurationData(uint nonce) public onlyOperator {
        if (addSignature(VALID_DURATION_DATA_INDEX, nonce, msg.sender)) {
            // can perform operation.
            conversionRates.setValidRateDurationInBlocks(validDurationData.durationInBlocks);
        }
    }

    function getValidDurationBlocksData() public view returns(uint validDuration, uint nonce) {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(VALID_DURATION_DATA_INDEX);
        return(nonce, validDurationData.durationInBlocks);
    }

    function getValidDurationSignatures() public view returns (address[] memory signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(VALID_DURATION_DATA_INDEX);
        return(signatures);
    }

    function performAddToken() internal {
        conversionRates.addToken(addTokenData.token);

        conversionRates.addOperator(this);

        //token control info
        conversionRates.setTokenControlInfo(
            addTokenData.token,
            addTokenData.minimalResolution,
            addTokenData.maxPerBlockImbalance,
            addTokenData.maxTotalImbalance
        );

        //step functions
        int[] memory zeroArr = new int[](1);
        zeroArr[0] = 0;

        conversionRates.setQtyStepFunction(addTokenData.token, zeroArr, zeroArr, zeroArr, zeroArr);
        conversionRates.setImbalanceStepFunction(addTokenData.token, zeroArr, zeroArr, zeroArr, zeroArr);

        conversionRates.enableTokenTrade(addTokenData.token);

        conversionRates.removeOperator(this);
    }

    function performSetTokenControlInfo() internal {
        require(tokenControlInfoData.tokens.length == tokenControlInfoData.perBlockImbalance.length);
        require(tokenControlInfoData.tokens.length == tokenControlInfoData.maxTotalImbalance.length);

        uint minRecordResolution;

        for (uint i = 0; i &lt; tokenControlInfoData.tokens.length; i++) {
            uint maxPerBlock;
            uint maxTotal;
            (minRecordResolution, maxPerBlock, maxTotal) =
                conversionRates.getTokenControlInfo(tokenControlInfoData.tokens[i]);
            require(minRecordResolution != 0);

            conversionRates.setTokenControlInfo(tokenControlInfoData.tokens[i],
                minRecordResolution,
                tokenControlInfoData.perBlockImbalance[i],
                tokenControlInfoData.maxTotalImbalance[i]);
        }
    }
}