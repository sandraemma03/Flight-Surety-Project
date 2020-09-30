const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function (deployer) {

    let firstAirline = '0xa1700d714770d04e01d0123932033b520fc2c08e';
    deployer.deploy(FlightSuretyData, {from: firstAirline}).then(() => {
            return deployer.deploy(FlightSuretyApp, FlightSuretyData.address).then(() => {

            let config = {
                localhost: {
                    url: 'ws://localhost:8545',
                    dataAddress: FlightSuretyData.address,
                    appAddress: FlightSuretyApp.address
                }
            };
            fs.writeFileSync(__dirname + '/../src/dapp/config.json', JSON.stringify(config, null, '\t'), 'utf-8');
            fs.writeFileSync(__dirname + '/../src/server/config.json', JSON.stringify(config, null, '\t'), 'utf-8');
            });
        });
};

