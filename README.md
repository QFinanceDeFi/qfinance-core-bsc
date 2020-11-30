# QFinance Core

### Trustless, decentralized investment pools on Ethereum

_Available live on the Kovan Ethereum testnet. Use https://qfihub.com to get started or to read more about how it works._

## Getting Started (Local)

You must install `nodeJS`

This guide uses `yarn` but you can use `npm` if you prefer.

### Install Dependencies

```bash
yarn
```

### Setup Environment

1. You can use either Alchemy API or Infura to get an environment. Get a project ID from there.
2. Recommended to create a new Metamask wallet (not connected to any mainnet funds as you will be using your seed.) You should create two addresses as the tests require 2.
3. Get test Kovan ETH from here: https://faucet.kovan.network.
4. Create a `secrets.json` file in the root. Add the following values:
   - projectId: [project Id from Infura/Alchemy],
   - mnemonic: [mnemonic phrase from Metamask],
   - address: [address from Metamask]

    *Note, the truffle-config file uses Infura so you will need to change the https address there if you chose to use Alchemy*
5. If you haven't install ganache-cli to create a local blockchain.

### Run Tests

1. Run the Ganache CLI first - we will run it by forking the Kovan Ethereum testnet so we can interact with it in its current state:

```bash
ganache-cli -f [Infura/Alchemy address with project ID] -m "seed phrase" -i 42 -u [address 1] -u [address 2]
```

2. Run tests:

```bash
truffle test --network development
```