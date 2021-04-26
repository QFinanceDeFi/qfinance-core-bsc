// Truffle Config File

const HDWalletProvider = require('@truffle/hdwallet-provider');
const { mnemonic, address, projectId } = require('./secrets.json');

module.exports = {

  networks: {
    // Local development blockchain
    development: {
     host: "127.0.0.1",
     port: 8545,
     network_id: "*",
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.4",
      docker: false,
      settings: {
       optimizer: {
         enabled: true,
         runs: 200
       }
      }
    },
  },
};