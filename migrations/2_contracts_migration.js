const MultiSigWallet = artifacts.require("MultiSig");

module.exports = async function(deployer, network, accounts) {
    const addresses = [];
    addresses.push(accounts[0], accounts[1], accounts[2]);
    await deployer.deploy(MultiSigWallet, addresses, 2);

    const multiSigWallet = await MultiSigWallet.deployed();
    console.log('Deployed address: ', multiSigWallet.address);
};