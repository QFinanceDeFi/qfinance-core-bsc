// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract QPoolPublic is ERC20, ERC20Burnable, ReentrancyGuard {
    using SafeMath for uint256;

    string public poolName;
    address[] private tokens;
    uint256[] private amounts;
    address public creator;
    address private pancakeRouterAddress = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    IPancakeRouter02 private pancakeRouter;
    
    mapping(address => uint) private deposits;
    uint256 public totalDeposits;
    
    event TradeCompleted(uint256[] acquired);
    event DepositProcessed(uint256 amount);
    event WithdrawalProcessed(uint256 amount);
    
    constructor (
        string memory _poolName,
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _creator
        ) ERC20 ("QPoolDepositToken", "QPDT") {
            uint256 _total = 0;
            require(tokens.length == amounts.length);
            for (uint256 i = 0; i < _amounts.length; i++) {
                _total += _amounts[i];
            }
            require(_total == 100);
            poolName = _poolName;
            tokens = _tokens;
            amounts = _amounts;
            creator = _creator;
            pancakeRouter = IPancakeRouter02(pancakeRouterAddress);
        }
    
    fallback() external payable nonReentrant {
        require(msg.data.length == 0);
        processDeposit();
    }

    receive() external payable nonReentrant {
        processDeposit();
    }

    function processDeposit() public payable nonReentrant {
        uint256 _newIssuance = calculateShare();
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        totalDeposits = totalDeposits.add(msg.value);
        require(makeExchange(), "Exchange failed");
        _mint(msg.sender, _newIssuance);
        emit DepositProcessed(msg.value);
    }

    function makeExchange() private returns (bool) {
        address[] memory _path = new address[](2);
        for (uint256 i = 0; i < tokens.length && i<= 5; i++) {
            _path[0] = pancakeRouter.WETH();
            _path[1] = tokens[i];
            uint256 _time = block.timestamp + 15 + i;
            uint256 _amountEth = msg.value.mul(amounts[i]).div(100);
            uint256[] memory _expected = pancakeRouter.getAmountsOut(_amountEth, _path);
            uint256[] memory _output = pancakeRouter.swapExactETHForTokens{value: _expected[0]}(_expected[1], _path, address(this), _time);
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
            _path[1] = pancakeRouter.WETH();
            uint256[] memory _ethValue = pancakeRouter.getAmountsOut(_totalBalance, _path);
            _totalValue += _ethValue[1];
        }
        return _totalValue;
    }

    function calculateShare() private view returns (uint256) {
        if (totalSupply() == 0) {
            return 1000000000000000000000;
        } else {
            uint256 _totalValue = totalValue();
            uint _tmp = 100;
            uint256 _poolShare = _tmp.mul(msg.value).div(_totalValue);
            uint256 _mintAmount = totalSupply().mul(_poolShare).div(100);
            return _mintAmount;
        }
    }
    
    function withdrawFunds(uint256 _percent) public nonReentrant {
        require(_percent > 0);
        uint256 _userShare = balanceOf(msg.sender);
        uint256 _burnAmount = _userShare.mul(_percent).div(100);
        uint256 _tmp = 100;
        uint256 _poolShare = _tmp.mul(_userShare).div(totalSupply());
        require(balanceOf(msg.sender) >= _burnAmount);
        require(approve(address(this), _burnAmount));
        _burn(msg.sender, _burnAmount);
        uint256 reduce = deposits[msg.sender].mul(_percent).div(100);
        (bool success, uint256 total) = sellTokens(_poolShare, _percent);
        require(success);
        deposits[msg.sender] = deposits[msg.sender].sub(reduce);
        totalDeposits = totalDeposits.sub(reduce);
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
            require(_token.approve(address(pancakeRouter), _amountOut));
            _path[0] = tokens[i];
            _path[1] = pancakeRouter.WETH();
            uint256[] memory _expected = pancakeRouter.getAmountsOut(_amountOut, _path);
            require(_expected[1] > 1000000);
            uint256 _time = block.timestamp + 15 + i;
            uint256[] memory _output = pancakeRouter.swapExactTokensForETH(_expected[0], _expected[1], _path, msg.sender, _time);
            total += _output[1];
            emit TradeCompleted(_output);
        }
        return (true, total);
    }

    function withdrawTokens() public nonReentrant {
        uint256 _userShare = balanceOf(msg.sender);
        uint256 _poolShare = _userShare.div(totalSupply()).mul(100);
        _burn(msg.sender, _userShare);
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 _token = ERC20(tokens[i]);
            uint256 _addressBalance = _token.balanceOf(address(this));
            uint256 _amountOut = _addressBalance.mul(_poolShare).div(100);
            require(_token.approve(msg.sender, _amountOut));
            require(_token.transfer(msg.sender, _amountOut));
        }
    }
    
    function checkDeposits(address _address) public view returns (uint256) {
        return deposits[_address];
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