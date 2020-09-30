var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "because symbol mail word almost crew age video mirror surround marine embrace";


module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      gas: 6721975,
      gasLimit: 20000000000

    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};