// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract QPool {
    using SafeMath for uint256;

    address public creator;
    string public poolName;
    address[] private tokens;
    uint[] private amounts;
    address private uniswapFactoryAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;

    event TradeCompleted(uint256[] acquired);
    event DepositProcessed(uint256 amount);
    event WithdrawalProcessed(uint256 amount);

    constructor(
        string memory _poolName,
        address[] memory _tokens,
        uint[] memory _amounts,
        address _creator
    ) public {
        uint _total = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            _total += _amounts[i];
        }
        require(_total == 100);
        creator = _creator;
        poolName = _poolName;
        tokens = _tokens;
        amounts = _amounts;
        uniswapRouter = IUniswapV2Router02(uniswapFactoryAddress);
    }

    fallback() external payable {
        require(msg.sender == creator);
        require(msg.data.length == 0);
        processDeposit();
    }

    receive() external payable {
        require(msg.sender == creator);
        require(msg.data.length == 0);
        processDeposit();
    }

    function close() external {
        require(msg.sender == creator);
        withdrawEth(100);
        selfdestruct(msg.sender);
    }

    function processDeposit() public payable {
        require(msg.sender == creator);
        require(msg.value > 10000000000000000, "Minimum deposit amount is 0.01 ETH");
        address[] memory _path = new address[](2);
        _path[0] = uniswapRouter.WETH();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 time = now + 15 + i;
            _path[1] = tokens[i];
            uint256 _amountEth = msg.value.mul(amounts[i]).div(100);
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountEth, _path);
            uint256[] memory _output = uniswapRouter.swapExactETHForTokens.value(_expected[0])(_expected[1], _path, address(this), time);
            emit TradeCompleted(_output);
        }
        emit DepositProcessed(msg.value);
    }

    function withdrawEth(uint256 _percent) public {
        require(msg.sender == creator, "Only the creator can withdraw ETH.");
        require(_percent > 0 && _percent <= 100, "Percent must be between 0 and 100.");
        address[] memory _path = new address[](2);
        uint256 total = 0;
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 _token = IERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_percent).div(100);
            require(_amountOut > 0, "Amount out is 0.");
            require(_token.approve(address(uniswapRouter), _amountOut), "Approval failed");
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _expected = uniswapRouter.getAmountsOut(_amountOut, _path);
            require(_expected[1] > 1000000, "Amount is too small to transfer");
            uint256 _time = now + 15 + i;
            uint256[] memory _output = uniswapRouter.swapExactTokensForETH(_expected[0], _expected[1], _path, creator, _time);
            total += _output[1];
            emit TradeCompleted(_output);
        }
        emit WithdrawalProcessed(total);
    }

    function totalValue() public view returns (uint256) {
        uint256 _totalValue = 0;
        address[] memory _path = new address[](2);
        for (uint i = 0; i < tokens.length && i <= 5; i++) {
            IERC20 _token = IERC20(tokens[i]);
            uint256 _totalBalance = _token.balanceOf(address(this));
            if (_totalBalance == 0) return 0;
            _path[0] = tokens[i];
            _path[1] = uniswapRouter.WETH();
            uint256[] memory _ethValue = uniswapRouter.getAmountsOut(_totalBalance, _path);
            _totalValue += _ethValue[1];
        }
        return _totalValue;
    }
    
    function withdrawTokens() public {
        require(msg.sender == creator, "Only the creator can withdraw tokens");
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 _token = IERC20(tokens[i]);
            uint256 _tokenBalance = _token.balanceOf(address(this));
            _token.transfer(creator, _tokenBalance);
        }
    }

    function getTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getAmounts() public view returns (uint[] memory) {
        return amounts;
    }

    function isPublic() public pure returns (bool _isPublic) {
        return false;
    }

}