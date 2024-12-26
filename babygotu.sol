pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
//-----------------------------------------------------------------------------------------------------------------------
// 标记：IERC20                                        接口 IERC20 标准代币接口
//-----------------------------------------------------------------------------------------------------------------------

interface IERC20 { 
    function totalSupply() external view returns (uint256);  //供应总量
    function balanceOf(address account) external view returns (uint256);//查询余额
    function transfer(address recipient, uint256 amount) external returns (bool);//代币转移
    function allowance(address owner, address spender) external view returns (uint256);//查询授权额度
    function approve(address spender, uint256 amount) external returns (bool); //
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }
//-----------------------------------------------------------------------------------------------------------------------
// 标记：IERC20Metadata       继承接口A （标准代币接口）             元信息  名字符号小数位
//-----------------------------------------------------------------------------------------------------------------------
interface IERC20Metadata is IERC20 { 
    function name() external view returns (string memory);  
    function symbol() external view returns (string memory); 
    function decimals() external view returns (uint8);
}
//-----------------------------------------------------------------------------------------------------------------------
// 标记：Context                                        抽象合约  用来获取调用函数的人的一些信息
//-----------------------------------------------------------------------------------------------------------------------
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; }
}

//*******************************************************************************************************************************
//以上部分都是 为后面的合约打下公用部分的基础的  他们都没有构造函数    两个接口  一个抽象合约
//*******************************************************************************************************************************





//-----------------------------------------------------------------------------------------------------------------------
// 标记:Ownable   （权利相关的合约）     继承抽象A （用来获取调用函数的人的一些信息）        Ownable合约  主要是所有权的一些函数
//
//当别的合约继承这个合约的时候，即表明子合约已经被部署者宣誓主权了
//-----------------------------------------------------------------------------------------------------------------------
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }  
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
//-----------------------------------------------------------------------------------------------------------------------
// 标记:合约ERC20        继承抽象context:（用来获取调用函数的人的一些信息）
//                      接口IERC20:(标准代币接口)
//                      接口IERC20Metadata：(名字符号小数位)
//                      未继承权利Owner合约     
//                                            ERC20实现合约
//-----------------------------------------------------------------------------------------------------------------------

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;//安全数学计算 应用于 数字变量类型
    mapping(address => uint256) private _balances; //余额映射
    mapping(address => mapping(address => uint256)) private _allowances;//授权额度
    uint256 private _totalSupply;//供应总量
    string private _name;//合约名字
    string private _symbol; //符号

    constructor(string memory name_, string memory symbol_)  {
        _name = name_;//名字
        _symbol = symbol_;//符号
    }

  
    function name() public view virtual override returns (string memory) { return _name;}
    function symbol() public view virtual override returns (string memory) { return _symbol;}
    function decimals() public view virtual override returns (uint8) { return 18;}
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        //调用自己写的转移函数，参数 谁调用的    发送给谁   发送数量
        return true;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        //                    授信人          被授信人
        return _allowances[owner][spender];
        // 查询授信额度  owner 授权给 spender 的数量
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        //                  被授信人          数量
        _approve(_msgSender(), spender, amount);
        //       授信人        被授信人   数量
        return true;
    }
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function transferFrom(address sender,address recipient,uint256 amount ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

   //增加授权额度
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

  //减少授权额度
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        //                    发送者           接受者           转移数量
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
//铸造代币 总量可以增加  内部函数 肯定有个外部函数可以调用这个函数
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
   //燃烧代币
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    /**
     * @dev 在任何代币转移之前被调用的钩子。这包括铸币和销毁。.
     *
     * 调用条件:
     *
     * - 当“from”和“to”都不为零时，“from”的“amount”数量的代币将被转移到“to”。
     当“from”为零时，“amount”数量的代币将为“to”铸造。
     当“to”为零时，“from”的“amount”数量的代币将被销毁。
     “from”和“to”永远不会同时为零。.
     *
     * 若要了解更多关于钩子（hooks）的信息，请前往“Using Hooks”（xref:ROOT:extending-contracts.adoc#using-hooks）。.
     */
    function _beforeTokenTransfer( address from, address to,uint256 amount ) internal virtual {}
}
//-----------------------------------------------------------------------------------------------------------------------
// 标记:合约C        不继承任何合约  传入一个地址就给他最大授权额度 但是仅仅一个数字而已啊
//-----------------------------------------------------------------------------------------------------------------------

contract TokenReceiver {
    constructor(address token) {
        IERC20(token).approve(msg.sender, type(uint256).max);
    }
}
//-----------------------------------------------------------------------------------------------------------------------
// 标记:合约D        一个空合约  可能是为了将来的某个合约重写
//-----------------------------------------------------------------------------------------------------------------------
contract ExtraFeeReceiver {}
//-----------------------------------------------------------------------------------------------------------------------
//                             继承抽象A（用来获取调用函数的人的一些信息）
//                             接口A(标准代币接口)
//                             接口B(名字符号小数位)
// 标记:合约E       继承了ERC20: 主要实现了接口     
//    
//                              继承抽象A（用来获取调用函数的人的一些信息）
//                 继承了Ownable ：合约所有权的一些函数                  
//
//                                       BabyGOUT   主合约
//-----------------------------------------------------------------------------------------------------------------------
contract BabyGOUT is ERC20, Ownable {
    //将安全数学库用于 非负整数
    using SafeMath for uint256;
//下面有个接口就是这个名字，swapv2路由器
    IUniswapV2Router02 public uniswapV2Router;
    //这也是一个地址 代表的是USDT
    address public uniswapV2PairUsdt;
    //这也是一个地址 代表的是 BNB
    address public uniswapV2PairBnb;

    bool private swapping;//交易
    bool public enableHoldDividend;//启动持仓分红

    DividendTracker public dividendTracker;//股息追踪器
    TokenReceiver public tokenReceiver;//代币接收者
    ExtraFeeReceiver public extraFeeReceiver;//额外费用接受者

    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant GOUT = 0xF86AF2FBcf6A0479B21b1d3a4Af3893F63207FE7;
    address public tokenOwner = 0x2ac8F7b42c8dbfC46C7949DeB713CcdCBcf52287;
    //marketing  促销
    address public marketingAddr = 0xa0845E9ecd06D1319880E055ea0bac80cDd64752;
    address public op;

    uint256 public numTokensSellToSwap = 1e26;//卖出到swap的代币数量
    uint256 public minTokenWhenAdd = 50 * 1e18;//当增加的时候的最小代币数量

    uint256 public buyLpFee = 1;//购买LP费率
    uint256 public buyMarketingFee = 1;//购买促销费率
    
    uint256 public sellLpFee = 1;//卖出LP费率
    uint256 public sellMarketingFee = 1;//卖出促销费率

    //  
    uint256 public gasForProcessing = 200000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;//是否排除在费用之外
    mapping (address => bool) private isPair;//是否币对
    mapping (address => uint) public principalOf;

    uint public startTime;//开始时间
    uint public airdropNum = 1;//空投数量
    uint public lastDeflationTime;//上次通缩时间
    uint public deflationFee = 50;//通缩费用

    uint256 public extraFee = 10;//额外费用
    uint256 public totalWeight;//总权重
    uint256 public accRewardPerShare;//累计每股奖励
    uint256 public minBurnToken = 5000 * 1e22;//最小燃烧代币数量

    struct UserInfo {//用户信息
        uint burned;//燃烧数量
        uint weight;//权重
        uint rewardPerSharePaid;//已支付的每股奖励
    }
    mapping (address => UserInfo) public userInfo;//映射：地址对应用户的信息

    modifier lockTheSwap {
        swapping = true;//当函数使用这个修饰符的时候，为了函数只可以被调用一次就恢复状态
        _;//这里是占位符 函数调用的时候会把逻辑插入此处
        swapping = false;
    }

    constructor() ERC20("BabyGOUT", "BabyGOUT") {
        //这是在声明变量                =  是赋值   这是合约实例
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ROUTER);
         // Create a uniswap pair for this new token

        address _uniswapV2PairUsdt = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDT);
        address _uniswapV2PairBnb = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), WBNB);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2PairUsdt = _uniswapV2PairUsdt;
        uniswapV2PairBnb = _uniswapV2PairBnb;
        //构造函数中就把代币对的是否建立的映射存起来
        isPair[_uniswapV2PairUsdt] = true;
        isPair[_uniswapV2PairBnb] = true;
//这里的TokenReceiver  是前面声明的一个合约，这个合约是调用者，也就是说这个合约新建一个新合约，就把传入的usdt地址传入新合约 并赋予最大值
        tokenReceiver = new TokenReceiver(USDT);
        //前面有个合约内容为空  就是这个   再创建一个新的合约实例变量
        extraFeeReceiver = new ExtraFeeReceiver();
        //这个是股息追踪器  是个合约  并且继承了两个合约  这里也是创建一个新的合约实例
        dividendTracker = new DividendTracker(USDT, _uniswapV2PairUsdt);
        //启动持仓分红开启
        enableHoldDividend = true;
        op = msg.sender;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(0));
        dividendTracker.excludeFromDividends(address(0xdead));

        // 将某些地址排除在最大金额限制之外   excludeFromFees  是这个合约中写的一个函数
        excludeFromFees(owner(), true);
        excludeFromFees(tokenOwner, true);
        excludeFromFees(marketingAddr, true);
        excludeFromFees(address(this), true);
//这就是给路由器批准额度   路由器可以使用本地址的最大额度为 最大值
        _approve(address(this), ROUTER, type(uint).max);

       
        //铸造代币  在构造函数中只能执行一次
        _mint(tokenOwner, 1000 * 1e26);
    }

    receive() external payable {}
//这个函数的作用其实是将 启动时间写入变量  以后这个变量是有用的 
    function startTrade() external onlyOwner {
        //启动时间
        startTime = block.timestamp;
        //最后通缩时间
        lastDeflationTime = block.timestamp;
    }
//设置营销地址，传入一个地址  就把新的营销地址传给变量
    function setMarketingAddr(address _marketingAddr) external onlyOwner {
        marketingAddr = _marketingAddr;
    }
//设置添加时的最小代币数
    function setMinTokenWhenAdd(uint _minTokenWhenAdd) external {
        require(msg.sender == op);
        minTokenWhenAdd = _minTokenWhenAdd;
    }
//设置最小燃烧代币数量
    function setMinBurnToken(uint _minBurnToken) external onlyOwner {
        minBurnToken = _minBurnToken;
    }
//设置空投数量
    function setAirdropNum(uint _airdropNum) external onlyOwner {
        airdropNum = _airdropNum;
    }
//设置通缩费用
    function setDeflationFee(uint _deflationFee) external {
        require(msg.sender == op);
        deflationFee = _deflationFee;
    }
//设置将某个地址排除在费用之外
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }
//设置排除多个账户的费用
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }
//设置买的费率
    function setBuyFees(uint _buyLpFee, uint _buyMarketingFee) external onlyOwner {
        buyLpFee = _buyLpFee;
        buyMarketingFee = _buyMarketingFee;
    }
//设置卖的费率
    function setSellFees(uint _sellLpFee, uint _sellMarketingFee) external onlyOwner {
        sellLpFee = _sellLpFee;
        sellMarketingFee = _sellMarketingFee;
    }
//设置额外费用
    function setExtraFee(uint _extraFee) external onlyOwner {
        extraFee = _extraFee;
    }
   //设置持有分红的最小金额 
    function setMinAmountForHoldDividend(uint256 value) external onlyOwner {
        dividendTracker.setMinimumTokenBalanceForDividends(value);
    }
//设置卖出到交易的代币数量
    function setNumTokensSellToSwap(uint256 value) external onlyOwner {
        numTokensSellToSwap = value;
    }
//设置持有分红开关
    function setEnableHoldDividend(bool value) external onlyOwner {
        enableHoldDividend = value;
    }

    function rescueERC20(address token, address to, uint amount) external onlyOwner {
        //如果 传入的token地址是本地址
        if (token == address(this)) {
            //调用父合约的转移函数  从本合约地址  转移到  to地址 amount数量的代币
            super._transfer(address(this), to, amount);
        } else {
            //否则 就将传入的地址的代币转移到to地址
            IERC20(token).transfer(to, amount);
        }  
    }

    function rescueETH(address to, uint amount) external {
        //构造函数创建的op其实就是部署合约的人，这里检查是不是这个人 其实就是限定了人员了
        require(msg.sender == op); 
        //payable 就是要转移ETH 到 to 地址  amount的数量
        payable(to).transfer(amount);
    }
//直译为 救援其他erc20代币
    function rescueOtherERC20(address token, address to, uint amount) external {
        //检查传入地址不是本地址
        require(token != address(this));
       //检查操作人是不是部署人
        require(msg.sender == op);
        //这个地址的代币转移到传入的to地址 amount的数量 
        IERC20(token).transfer(to, amount);
    }




//更新用于处理的 Gas 量
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        //传入的值 要在一个范围内
        require(newValue >= 100000 && newValue <= 250000, "ETHBack: gasForProcessing must be between 100,000 and 250,000");
        //传入的值不能等于以前就设定的值
        require(newValue != gasForProcessing, "ETHBack: Cannot update gasForProcessing to same value");
         //赋予新值
        gasForProcessing = newValue;
    }
//更新索赔等待
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        //调用这个函数
        dividendTracker.updateClaimWait(claimWait);
    }
//查询是否排除在费用之外
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");

        if (from != uniswapV2PairBnb && lastDeflationTime != 0 && block.timestamp - lastDeflationTime >= 1 hours) {
            uint deflationAmount = balanceOf(uniswapV2PairBnb) * deflationFee / 10000;
            super._transfer(uniswapV2PairBnb, address(0xdead), deflationAmount);
            lastDeflationTime = block.timestamp;
            IUniswapV2Pair(uniswapV2PairBnb).sync();
        }

        if (from.code.length == 0) {
            _updateRewards(from);
            if (to == GOUT) {
                UserInfo storage ui = userInfo[from];
                ui.burned += amount;
                if (ui.burned >= minBurnToken) {
                    uint addWeight = ui.burned - ui.weight;
                    ui.weight += addWeight;
                    totalWeight += addWeight;
                    ui.rewardPerSharePaid = accRewardPerShare;
                }
            }
        }
        if (to.code.length == 0) {
            _updateRewards(to);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToSwap;

        if( overMinTokenBalance && !swapping && !isPair[from]) {
            swapAndDividend(numTokensSellToSwap);
        } 

        uint256 extraFeeBalance = balanceOf(address(extraFeeReceiver));
        if( extraFeeBalance >= numTokensSellToSwap && !swapping && !isPair[from] ) {
            swapAndDividendExtraFee(numTokensSellToSwap);
        }

        bool takeFee = !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee); 

        if (from.code.length == 0) {
            try dividendTracker.setBalance(from, IERC20(uniswapV2PairUsdt).balanceOf(from)) {} catch {}
        }
        if (to.code.length == 0) {
            try dividendTracker.setBalance(to, IERC20(uniswapV2PairUsdt).balanceOf(to)) {} catch {}
        }
        
        if(!swapping && enableHoldDividend) {
            uint256 gas = gasForProcessing;
            try dividendTracker.process(gas) {} catch {}
            try dividendTracker.reset(gas) {} catch {}
        }
    }

    function _updateRewards(address account) private {
        UserInfo storage ui = userInfo[account];
        if (ui.weight == 0) return;
        uint pending = ui.weight * (accRewardPerShare - ui.rewardPerSharePaid) / 1e18;
        if (pending > 0 && IERC20(USDT).balanceOf(address(this)) >= pending) {
            ui.rewardPerSharePaid = accRewardPerShare;
            IERC20(USDT).transfer(account, pending);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(takeFee) {
            if (airdropNum > 0 && balanceOf(address(this)) >= airdropNum * 1e18) {
                for (uint8 i; i < airdropNum; i++) {
                    super._transfer(address(this), address(uint160(uint(keccak256(abi.encodePacked(balanceOf(address(this)), block.timestamp))))), 1e18);
                } 
            }
            (bool isAdd, bool isRemove) = isAddOrRemoveLp(sender, recipient);
            uint256 feeToThis;
            uint oAmount = amount;
            if(isPair[sender]) { //buy
                require(startTime > 0);
                if (!isRemove) {
                    feeToThis = buyLpFee + buyMarketingFee;
                    address[] memory path = new address[](2);
                    path[0] = USDT;
                    path[1] = address(this);
                    uint[] memory amountsIn = uniswapV2Router.getAmountsIn(amount, path);
                    principalOf[recipient] += amountsIn[0];
                }
            } else if (isPair[recipient]) {
                require(startTime > 0);
                if (!isAdd) {
                    feeToThis = sellLpFee + sellMarketingFee;
                    uint extraFeeAmount;
                    address[] memory path1 = new address[](2);
                    path1[0] = address(this);
                    path1[1] = USDT;
                    uint[] memory amountsOut = uniswapV2Router.getAmountsOut(amount, path1);
                    uint amountOut = amountsOut[1];
                    if (principalOf[sender] >= amountOut) {
                        principalOf[sender] -= amountOut;
                    } else {
                        uint profit = amountOut - principalOf[sender];
                        uint[] memory amountsIn = uniswapV2Router.getAmountsIn(profit, path1);
                        extraFeeAmount = amountsIn[0] * extraFee / 100;
                        principalOf[sender] = 0;
                    }

                    if (extraFeeAmount > 0) {
                        super._transfer(sender, address(extraFeeReceiver), extraFeeAmount);
                        amount -= extraFeeAmount;
                    } 
                }
            }

            if(feeToThis > 0) {
                uint256 feeAmount = oAmount * feeToThis / 100;
                super._transfer(sender, address(this), feeAmount);
                amount -= feeAmount;
            }
        }
        super._transfer(sender, recipient, amount);
    }
//交换和分红
    function swapAndDividend(uint256 tokenAmount) private lockTheSwap {
        uint totalBuyShare = buyLpFee + buyMarketingFee;
        uint totalSellShare = sellLpFee + sellMarketingFee;

        // generate the uniswap pair path of token -> USDT
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        uint256 initialBalance = IERC20(USDT).balanceOf(address(tokenReceiver));
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(tokenReceiver),
            block.timestamp
        );
        uint256 newBalance = IERC20(USDT).balanceOf(address(tokenReceiver)) - initialBalance;
        uint bToLp = newBalance * (buyLpFee + sellLpFee) / (totalBuyShare + totalSellShare);
        IERC20(USDT).transferFrom(address(tokenReceiver), address(dividendTracker), bToLp);
        dividendTracker.distributeETHDividends(bToLp);

        uint256 bToM = newBalance - bToLp;
        IERC20(USDT).transferFrom(address(tokenReceiver), marketingAddr, bToM);
    }
//交换和股息额外费用
    function swapAndDividendExtraFee(uint256 tokenAmount) private lockTheSwap {
        super._transfer(address(extraFeeReceiver), address(this), tokenAmount);
        // generate the uniswap pair path of token -> USDT
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        uint256 initialBalance = IERC20(USDT).balanceOf(address(tokenReceiver));
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(tokenReceiver),
            block.timestamp
        );
        uint256 newBalance = IERC20(USDT).balanceOf(address(tokenReceiver)) - initialBalance;
        IERC20(USDT).transferFrom(address(tokenReceiver), address(this), newBalance);
        if (totalWeight > 0) {
            accRewardPerShare += (newBalance * 1e18 / totalWeight);
        }
    }
//是否增加或移除流动性
    function isAddOrRemoveLp(address from, address to) private view returns (bool, bool) {
        address token0 = IUniswapV2Pair(uniswapV2PairUsdt).token0();
        (uint reserve0,,) = IUniswapV2Pair(uniswapV2PairUsdt).getReserves();
        uint balance0 = IERC20(token0).balanceOf(uniswapV2PairUsdt);

        if (from == uniswapV2PairUsdt && reserve0 > balance0) { // remove
            return (false, true);
        }

        if (to == uniswapV2PairUsdt && reserve0 + minTokenWhenAdd < balance0) { // add
            return (true, false);
        }
        return (false, false);
    }
}

interface DividendPayingTokenOptionalInterface {
/// @notice 查看某个地址可提取的以 wei 为单位的分红金额。
  /// @param _owner 代币持有者的地址。
  /// @return `_owner`可提取的以 wei 为单位的分红金额。
  function withdrawableDividendOf(address _owner) external view returns(uint256);

 /// @notice 查看某个地址已提取的以 wei 为单位的分红金额。
/// @param _owner 代币持有者的地址。
/// @return `_owner`已提取的以 wei 为单位的分红金额。
  function withdrawnDividendOf(address _owner) external view returns(uint256);

/// @notice 查看一个地址总共赚取的以 wei 为单位的股息金额。
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner 代币持有者的地址。
  /// @return `_owner`总共赚取的以 wei 为单位的股息金额。
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/// @title 分红代币
/// @author Roger Wu（https://github.com/roger-wu）
/// @dev 一种可铸造的 ERC20 代币，允许任何人以股息的形式向代币持有者支付和分配以太币，并允许代币持有者提取他们的股息。
/// 参考：PoWH3D 的源代码：https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code

/// @title 分红代币接口
/// @author Roger Wu（https://github.com/roger-wu）
/// @dev 一个分红代币合约的接口。
interface DividendPayingTokenInterface {
/// @notice 查看一个地址可以提取的以 wei 为单位的股息金额。
  /// @param _owner 代币持有者的地址。
  /// @return `_owner`可以提取的以 wei 为单位的股息金额。
  function dividendOf(address _owner) external view returns(uint256);


/// @notice 提取发送者所分配到的以太币。
  /// @dev 应当将`dividendOf(msg.sender)`数量的 wei 转移给`msg.sender`，并且在转移后`dividendOf(msg.sender)`应当为 0。
  /// 如果转移的以太币数量大于 0，则必须触发一个`DividendWithdrawn`事件。
  function withdrawDividend() external;

  /// @dev 当以太币分配给代币持有者时，必须触发此事件。
/// @param from 向此合约发送以太币的地址。
/// @param weiAmount 以 wei 为单位的分配的以太币数量。
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

/// @dev 当一个地址提取他们的分红时，必须触发此事件。
/// @param to 从本合约提取以太币的地址。
/// @param weiAmount 以 wei 为单位的提取的以太币数量。
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}
//分红代币合约模块  继承 代币基本实现  权限  分红代币接口  可选的代币分红接口
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
//成立一个地址  用于奖励
  address public immutable rewardToken; 


// 使用“量级”，即使收到的以太币数量很少，我们也能正确分配股息。
  // 关于选择“量级”值的更多讨论，请参阅 https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728。
  //magnitude  翻译为量级 这是一个常量
  uint256 constant internal magnitude = 2**128;
//翻译为 放大后的每股股息
  uint256 internal magnifiedDividendPerShare;

// 关于股息修正：
// 如果 `_user` 的代币余额从未改变，那么 `_user` 的股息可以通过以下方式计算：
// `dividendOf(_user) = dividendPerShare * balanceOf(_user)`。
// 当 `balanceOf(_user)` 发生变化（通过铸造/销毁/转移代币）时，
// `dividendOf(_user)` 不应改变，
// 但 `dividendPerShare * balanceOf(_user)` 的计算值会发生变化。
// 为了保持 `dividendOf(_user)` 不变，我们添加一个修正项：
// `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`，
// 其中每当 `balanceOf(_user)` 发生变化时，`dividendCorrectionOf(_user)` 就会更新：
// `dividendCorrectionOf(_user) = dividendPerShare * (旧的 balanceOf(_user)) - (新的 balanceOf(_user))`。
// 所以现在 `dividendOf(_user)` 在 `balanceOf(_user)` 改变前后返回相同的值。

//映射 放大后的股息修正
  mapping(address => int256) internal magnifiedDividendCorrections;
  //已经提取的股息
  mapping(address => uint256) internal withdrawnDividends;
//已经分配的总股息
  uint256 public totalDividendsDistributed;
//构造函数 传入三个参数是给自己的 传入两个参数是给父合约的，这样就可以让父合约重构
  constructor(string memory _name, string memory _symbol, address _rewardToken) ERC20(_name, _symbol) {
     rewardToken = _rewardToken;
  }

//分发以太币股息   估计这个函数也会被调用 
  function distributeETHDividends(uint256 amount) public onlyOwner{
    //如果供应总量为0  这里的供应总量是重构ERC20来的，也就是说这个股息的计算是根据重新传入的分红币地址来计算的
    //这里的意思是 你传入什么数先不管  如果没有分红的话，直接就返回了
    if(totalSupply() == 0) return;
    //这里传入的amount应该是所有要分的以太币股息的和，这里是要算出每股多少钱
    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(msg.sender);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(rewardToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

//写个合约 模块  股息追踪器  这个合约要继承 权限模块合约  继承
contract DividendTracker is Ownable, DividendPayingToken {

    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    uint256 public lastResetedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    address public lpAddr;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(address rewardToken, address _lpAddr) DividendPayingToken("Dividen_Tracker", "Dividend_Tracker", rewardToken) {
        claimWait = 600;
        lpAddr = _lpAddr;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "ETHBack_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "ETHBack_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ETHBack contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }
//主合约也调用这个函数
    function setMinimumTokenBalanceForDividends(uint256 value) external onlyOwner {
        minimumTokenBalanceForDividends = value;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait != claimWait, "ETHBack_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return;
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];
            uint newBalance = IERC20(lpAddr).balanceOf(account);
            _setBalance(account, newBalance);

            if(canAutoClaim(lastClaimTimes[account])) {
                processAccount(account, true);
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;
    }

    function reset(uint256 gas) public {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return;
        }

        uint256 _lastResetedIndex = lastResetedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastResetedIndex++;

            if(_lastResetedIndex >= tokenHoldersMap.keys.length) {
                _lastResetedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastResetedIndex];
            uint newBalance = IERC20(lpAddr).balanceOf(account);
            _setBalance(account, newBalance);

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastResetedIndex = _lastResetedIndex;
    }

    function processAccount(address account, bool automatic) public onlyOwner {
        uint256 amount = _withdrawDividendOfUser(account);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
        }
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/**
 * @title SafeMathUint
 * @dev 出现错误的时候可以回退，uint为非负整数， 对传入的非负数 进行检查
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}