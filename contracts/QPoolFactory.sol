// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "./QPool.sol";
import "./QPoolPublic.sol";

contract QPoolFactory {
    address[] private allPools;
    address[] private privatePools;
    address[] private publicPools;
    mapping(address => bool) private isPool;

    event PoolCreated(QPool pool);
    event PublicPoolCreated(QPoolPublic pool);

    function getPrivatePools() public view returns (address[] memory) {
        return privatePools;
    }

    function getPublicPools() public view returns (address[] memory) {
        return publicPools;
    }

    function checkPool(address _poolAddress) public view returns (bool) {
        return isPool[_poolAddress];
    }

    function newPool(string memory _name, address[] memory _tokens, uint[] memory _amounts)
    public returns (address) {
        QPool pool = new QPool(_name, _tokens, _amounts, msg.sender);
        emit PoolCreated(pool);
        allPools.push(address(pool));
        privatePools.push(address(pool));
        isPool[address(pool)] = true;
        return address(pool);
    }

    function newPublicPool(string memory _name, address[] memory _tokens, uint[] memory _amounts)
    public returns (address) {
        QPoolPublic pool = new QPoolPublic(_name, _tokens, _amounts, msg.sender);
        emit PublicPoolCreated(pool);
        allPools.push(address(pool));
        publicPools.push(address(pool));
        isPool[address(pool)] = true;
    }
}