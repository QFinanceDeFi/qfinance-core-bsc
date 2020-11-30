const Factory = artifacts.require("QPoolFactory.sol")

module.exports = function (deployer) {
    deployer.deploy(Factory);
}