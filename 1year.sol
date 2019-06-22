
// ----------------------------------------------------------------------------
// 'ONEYEAR Token' contract
// Mineable ERC20 Token using Proof Of Work
//
// Symbol      : ONEYEAR
// Name        : ONEYEAR Token
// Total supply: 1000000
// Decimals    : 0
//
// ----------------------------------------------------------------------------


pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
	assert(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}


contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract ONEYEAR is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _blockStart;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "ONEYEAR";
  string constant tokenSymbol = "ONEYEAR";
  uint8 constant tokenDecimals = 0;
  uint256 constant dayBlocks = 6000; // BLOCKS MINED PER DAY ON ETH BLOCKCHAIN
  uint256 constant limitTime = 7;
  
  uint256 _limitBlocks = dayBlocks*limitTime/100; // 1% BLOCKS PER LIMITTIME
  uint256 _totalSupply = 1000000;
  
  
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function findOnePercent(uint256 value) public pure returns (uint256)  {
    uint256 roundValue = value.ceil(100);
    uint256 onePercent = roundValue.mul(100).div(10000);
    return onePercent;
  }
  
  function getBlocksDifference(address owner) public view returns (uint256)  {
	require(owner != address(0));
	return block.number - _blockStart[owner];
  }
  
  function getLimitBlocksPercentual(address owner) public view returns (uint256)  {
	require(owner != address(0));
	if (getBlocksDifference(owner)/_limitBlocks <= 0) {
		return 1;
	}
	return getBlocksDifference(owner)/_limitBlocks;
  }
  
  function setNewStartBlock(address to, uint256 blockNumber, uint256 value) public view returns (uint256)  {
    require(value > 0);
    require(to != address(0));
	
	if(_blockStart[to] == 0) {
		return blockNumber;
	}
		
	uint256 tempTokenAmount = getLimitBlocksPercentual(to)*_balances[to]/100 + value/100;
	uint256 tempNewBlockStart = blockNumber - tempTokenAmount*_limitBlocks*100/(_balances[to]+value);

    return tempNewBlockStart;
  }
  
  
  // ******************
  // TRANSFER FUNCTIONS
  // ******************

  function transfer(address to, uint256 value) public returns (bool) {
	require(value <= _balances[msg.sender]);
    require(to != address(0));
	
	uint256 tokensToBurn = 0;
    uint256 tokensToTransfer = 0;

	_balances[msg.sender] = _balances[msg.sender].sub(value);

	if(_blockStart[msg.sender] == 0) { // OWNER ADDRESS SENDING TOKENS
		
		tokensToBurn = findOnePercent(value);
		tokensToTransfer = value.sub(tokensToBurn);

		_blockStart[to] = block.number;
		
		_balances[to] = _balances[to].add(tokensToTransfer);
		
		_totalSupply = _totalSupply.sub(tokensToBurn);
		
	} else {
	
		tokensToBurn = findOnePercent(value)*getLimitBlocksPercentual(msg.sender);
		tokensToTransfer = value.sub(tokensToBurn);
		
		_blockStart[to] = setNewStartBlock (to, block.number, tokensToTransfer);
		
		_balances[to] = _balances[to].add(tokensToTransfer);

		_totalSupply = _totalSupply.sub(tokensToBurn);	
	}
	
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
	
    return true;
  }
  
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
	
	uint256 tokensToBurn = 0;
    uint256 tokensToTransfer = 0;

	if(_blockStart[msg.sender] == 0) { // OWNER ADDRESS SENDING TOKENS
		
		tokensToBurn = findOnePercent(value);
		tokensToTransfer = value.sub(tokensToBurn);

		_blockStart[to] = block.number;
		
		_balances[to] = _balances[to].add(tokensToTransfer);
		
		_totalSupply = _totalSupply.sub(tokensToBurn);
		
	} else {
	
		tokensToBurn = findOnePercent(value)*getLimitBlocksPercentual(msg.sender);
		tokensToTransfer = value.sub(tokensToBurn);
		
		_blockStart[to] = setNewStartBlock (to, block.number, tokensToTransfer);
		
		_balances[to] = _balances[to].add(tokensToTransfer);

		_totalSupply = _totalSupply.sub(tokensToBurn);	
	}

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
  
  
  // ***************
  // DEBUG FUNCTIONS
  // ***************
  
  function getStartBlock(address to) public view returns (uint256) {
    return _blockStart[to];
  }
  
  function getLimitBlocks() public view returns (uint256) {
    return _limitBlocks;
  }
  
  function getDayBlocks() public pure returns (uint256) {
    return dayBlocks;
  }
  
  function getLimitTime() public pure returns (uint256) {
    return limitTime;
  }
  

  // *******************+
  // ALLOWANCE FUNCTIONS
  // *******************

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }


  // *************
  // MINT FUNCTION
  // *************
  
  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
	_blockStart[account] = 0; // NO BLOCK NUMBER TO DISTRIBUTE FIRST TIME ONLY WITH 1% BURNING
    emit Transfer(address(0), account, amount);
  }
  
  
  // **************
  // BURN FUNCTIONS
  // **************
  
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}