const QPoolFactory = artifacts.require("QPoolFactory.sol");
const QPoolPrivate = artifacts.require("QPool.sol");
const QPoolPublic = artifacts.require("QPoolPublic.sol");
const web3 = require('web3');
const daiAddress = web3.utils.toChecksumAddress("0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa");
const uniAddress = web3.utils.toChecksumAddress("0x1f9840a85d5af5bf1d1762f925bdaddc4201f984");

const tokenList = [daiAddress, uniAddress]

contract("QPoolFactory", async accounts => {
    it("Deploy QPoolFactory and create private pool", async () => {
        let qfactory = await QPoolFactory.deployed();
        await qfactory.newPool(
            "New Pool", tokenList, [50,50]
        );
        let newPool = await qfactory.getPrivatePools.call();
        assert.equal(newPool.length, 1, 'No pool created');
    })

    it("Deploy QPoolFactory and create public pool", async () => {
        let qfactory = await QPoolFactory.deployed();
        await qfactory.newPublicPool(
            "New Pool", tokenList, [50,50]
        );
        let newPool = await qfactory.getPublicPools.call();
        assert.equal(newPool.length, 1, 'No pool created');
    })

    it("Deposit ETH to private pool", async () => {
        let qfactory = await QPoolFactory.deployed();
        await qfactory.newPool(
            "New Pool", tokenList, [50,50]
        );
        let newPool = await qfactory.getPrivatePools.call();
        let pool = await QPoolPrivate.at(newPool[0]);
        let value = web3.utils.toWei('.1', 'ether');
        await pool.processDeposit.sendTransaction({from: accounts[0], value});
        await pool.withdrawEth.sendTransaction(100, {from: accounts[0]});
    })

    it("Deposit ETH to public pool", async () => {
        // Deploy factory
        let qfactory = await QPoolFactory.deployed();
        await qfactory.newPublicPool(
            "New Pool", tokenList, [50,50]
        );
        // Create pool
        let newPool = await qfactory.getPublicPools.call();
        let pool = await QPoolPublic.at(newPool[0]);

        // Set transfer values in Wei
        let valueOne = web3.utils.toWei('1', 'ether');
        let valueTwo = web3.utils.toWei('0.5', 'ether');

        // Make Deposits from each account
        await pool.processDeposit.sendTransaction(
            {from: accounts[0], value: valueOne}
            );
        await pool.processDeposit.sendTransaction(
            {from: accounts[1], value: valueTwo}
            );

        // Get balances
        let balanceOne = await pool.balanceOf.call(accounts[0]);
        let balanceTwo = await pool.balanceOf.call(accounts[1]);
 
        // Test that balances are processed correctly
        assert.equal(balanceOne, web3.utils.toWei('1000', 'ether'));
        assert.equal(balanceTwo, web3.utils.toWei('500', 'ether'));
        
        // Withdraw deposit
        await pool.withdrawEth.sendTransaction(50, {from: accounts[0]})
        await pool.withdrawEth.sendTransaction(100, {from: accounts[1]})

        // Check balances
        balanceOne = await pool.balanceOf.call(accounts[0]);
        balanceTwo = await pool.balanceOf.call(accounts[1]);

        assert.equal(balanceOne, web3.utils.toWei('500', 'ether'));
        assert.equal(balanceTwo, 0);

        // Final withdrawal
        await pool.withdrawEth.sendTransaction(100, {from: accounts[0]});
        balanceOne = await pool.balanceOf.call(accounts[0]);

        assert.equal(balanceOne, 0);
    })

})