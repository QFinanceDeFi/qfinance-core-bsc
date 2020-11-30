// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract QPoolPublic is ERC20, ERC20Burnable, ReentrancyGuard {
    using SafeMath for uint256;

    string public poolName;
    address[] private tokens;
    uint256[] private amounts;
    address public creator;
    address private uniswapFactoryAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;
    
    address[] private depositors;
    mapping(address => uint) private deposits;
    
    event TradeCompleted(uint256[] acquired);
    event DepositProcessed(uint256 amount);
    event WithdrawalProcessed(uint256 amount);
    
    constructor (
        string memory _poolName,
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _creator
        ) ERC20 ("QPoolDepositToken", "QPDT") public {
            uint256 _total = 0;
            require(tokens.length <= 5 && tokens.length == amounts.length);
            for (uint256 i = 0; i < _amounts.length && i <= 5; i++) {
                _total += _amounts[i];
            }
            require(_total == 100);
            poolName = _poolName;
            tokens = _tokens;
            amounts = _amounts;
            creator = _creator;
            uniswapRouter = IUniswapV2Router02(uniswapFactoryAddress);
        }
    
    fallback() external payable nonReentrant {
        require(msg.data.length == 0);
        processDeposit();
    }

    receive() external payable nonReentrant {
        require(msg.data.length == 0);
        processDeposit();
    }

    function processDeposit() public payable nonReentrant {
        uint256 _newIssuance = calculateShare();
        if (deposits[msg.sender] == 0) addDepositor(msg.sender);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        require(makeExchange());
        _mint(msg.sender, _newIssuance);
        emit DepositProcessed(msg.value);
    }

    function makeExchange() private returns (bool) {
        address[] memory _path = new address[](2);
        for (uint256 i = 0; i < tokens.length && i<= 5; i++) {
            _path[0] = uniswapRouter.WETH();
            _path[1] = tokens[i];
            uint256 _time = now + 15 + i;
            uint256 _amountEth = msg.value.mul(amounts[i]).div(100);
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountEth, _path);
            uint256[] memory _output = uniswapRouter.swapExactETHForTokens.value(_expected[0])(_expected[1], _path, address(this), _time);
            emit TradeCompleted(_output);
        }
        return true;
    }

    function totalValue() public view returns (uint256) {
        uint256 _totalValue = 0;
        address[] memory _path = new address[](2);
        for (uint i = 0; i < tokens.length && i <= 5; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _totalBalance = _token.balanceOf(address(this));
            if (_totalBalance == 0) return 0;
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _ethValue = uniswapRouter.getAmountsOut(_totalBalance, _path);
            _totalValue += _ethValue[1];
        }
        return _totalValue;
    }

    function calculateShare() private view returns (uint256) {
        if (totalSupply() == 0) {
            return 1000000000000000000000;
        } else {
            uint256 _totalValue = totalValue();
            uint256 _tmp = 100;
            uint256 _poolShare = _tmp.mul(msg.value).div(_totalValue);
            uint256 _mintAmount = totalSupply().mul(_poolShare).div(100);
            return _mintAmount;
        }
    }
    
    function withdrawEth(uint256 _percent) public nonReentrant {
        require(_percent > 0);
        uint256 _userShare = balanceOf(msg.sender);
        uint256 _burnAmount = _userShare.mul(_percent).div(100);
        uint256 _tmp = 100;
        uint256 _poolShare = _tmp.mul(_userShare).div(totalSupply());
        require(balanceOf(msg.sender) >= _burnAmount);
        require(approve(address(this), _burnAmount));
        _burn(msg.sender, _burnAmount);
        deposits[msg.sender] = deposits[msg.sender].sub((deposits[msg.sender]).mul(_percent).div(100));
        if (deposits[msg.sender] == 0) removeDepositor(msg.sender);
        (bool success, uint256 total) = sellTokens(_poolShare, _percent);
        require(success);
        emit WithdrawalProcessed(total);
    }

    function sellTokens(uint256 _poolShare, uint256 _percent) private returns (bool, uint256) {
        uint256 total = 0;
        address[] memory _path = new address[](2);
        for (uint256 i = 0; i < tokens.length && i <= 5; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_poolShare).mul(_percent).div(10000);
            require(_amountOut > 0);
            require(_token.approve(address(uniswapRouter), _amountOut));
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountOut, _path);
            require(_expected[1] > 1000000);
            uint256 _time = now + 15 + i;
            uint256[] memory _output = uniswapRouter.swapExactTokensForETH(_expected[0], _expected[1], _path, msg.sender, _time);
            total += _output[1];
            emit TradeCompleted(_output);
        }
        return (true, total);
    }

    function withdrawTokens() public nonReentrant {
        uint256 _userShare = balanceOf(msg.sender);
        uint256 _poolShare = _userShare.div(totalSupply()).mul(100);
        _burn(msg.sender, _userShare);
        removeDepositor(msg.sender);
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_poolShare).div(100);
            require(_token.approve(msg.sender, _amountOut));
            require(_token.transfer(msg.sender, _amountOut));
        }
    }
    
    function isDepositor(address _address) public view returns (bool, uint256) {
        for (uint256 i = 0; i < depositors.length; i++) {
            if (_address == depositors[i]) return (true, i);
        }
        return (false, 0);
    }
        
    function totalDeposits() public view returns (uint256) {
        uint256 _totalDeposits = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            _totalDeposits = _totalDeposits.add(deposits[depositors[i]]);
        }
        return _totalDeposits;
    }
    
    function addDepositor(address _depositor) private {
        (bool _isDepositor, ) = isDepositor(_depositor);
        if(!_isDepositor) depositors.push(_depositor);
    }
    
    function removeDepositor(address _depositor) private {
        (bool _isDepositor, uint256 i) = isDepositor(_depositor);
        if (_isDepositor) {
            depositors[i] = depositors[depositors.length - 1];
            depositors.pop();
        }
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getAmounts() public view returns (uint[] memory) {
        return amounts;
    }

    function isPublic() public pure returns (bool _isPublic) {
        return true;
    }
}