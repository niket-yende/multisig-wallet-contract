const MultiSigWallet = artifacts.require("MultiSigWallet");

module.exports = async function(deployer) {
    const addresses = ['0xb0fd0Fa5Cf4Fb79e5Ae0938Cc5fCc757e3DD0AB8', '0x27fB8cc725Aa31b78Bf4F385c1c307Ae9d7eDd38', '0x8cfeD0390B84E6e93e04f753382Ee2629ce01014'];
    await deployer.deploy(MultiSigWallet, addresses, 2);

    const multiSigWallet = await MultiSigWallet.deployed();
    console.log('Deployed address: ', multiSigWallet.address);
};