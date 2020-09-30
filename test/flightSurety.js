var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;

  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeContract(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try
    {
        await config.flightSuretyApp.setOperatingStatus(false, {"from": accounts[2]});
    }
    catch(e) {
        accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
    await config.flightSuretyApp.setOperatingStatus(true, {from: config.firstAirline});


  });



    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        await config.flightSuretyApp.setOperatingStatus(false);

        let reverted = false;
        try
        {
            await config.flightSuretyApp.setTestingMode(true);
        }
        catch(e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyApp.setOperatingStatus(true);
    });

    

    

    it('(airline) can fund the first airline', async () => {
        let result = await config.flightSuretyApp.isActivated.call(config.firstAirline);

        assert.equal(result, false, "airline is not active");

        await config.flightSuretyApp.activeAirline.sendTransaction(config.firstAirline, {
            from: config.firstAirline,
            value: config.weiMultiple * 10
        });

        let result2 = await config.flightSuretyApp.isActivated.call(config.firstAirline);

        assert.equal(result2, true, "airline is active after funded");
        console.log("is airline active?", result2)
    });


    it('(airline) can register first airline when contract is deployed.', async () => {

        await config.flightSuretyApp.registerAirline(config.firstAirline, {from: config.firstAirline});

    });


    
    it('(multiparty) Only existing airline may register a new airline until there are at least four airlines registered', async function () {

        let newLine2 = accounts[2];
        let newLine3 = accounts[3];
        let newLine4 = accounts[4];

        await config.flightSuretyApp.registerAirline(newLine2, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(newLine3, {from: config.firstAirline});
        await config.flightSuretyApp.registerAirline(newLine4, {from: config.firstAirline});

    });

    it('(airline) can fund airlines which are registered', async () => {

        let newLine2 = accounts[2];
        let newLine3 = accounts[3];
        let newLine4 = accounts[4];

        await config.flightSuretyApp.fund(newLine2, {
            from: config.firstAirline,
            value: 10
        });

        await config.flightSuretyApp.fund(newLine3, {
            from: config.firstAirline,
            value: 10
        });

        await config.flightSuretyApp.fund(newLine4, {
            from: config.firstAirline,
            value: 10
        });

    });
   
   


    it('(airline) can registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines', async () => {
        reg = await config.flightSuretyData.getRegisteredAirlines.call()
        console.log('Number of registered airlines:',reg.toNumber())

        await config.flightSuretyData.approveAirlineRegistration(accounts[5], true, {from: config.firstAirline});
        await config.flightSuretyData.approveAirlineRegistration(accounts[5], true, {from: accounts[2]});
        await config.flightSuretyData.approveAirlineRegistration(accounts[5], false, {from: accounts[3]});
        await config.flightSuretyData.approveAirlineRegistration(accounts[5], false, {from: accounts[4]});

        

        let votes = await config.flightSuretyData.getVotes.call(accounts[5]);
        console.log('Number of accounts which voted to register the 5th airline',votes.toNumber());    
        
        
        let checkRegistration = await config.flightSuretyData.isAirline.call(accounts[5])
        assert.equal(checkRegistration, false, "Was unable to register the airline")
        console.log("Is the airline resistered before calling registerAirlines? ", checkRegistration)

        await config.flightSuretyApp.registerAirline(accounts[5], { from: config.firstAirline })

        let checkRegistration2 = await config.flightSuretyData.isAirline.call(accounts[5])
        assert.equal(checkRegistration2, true, "Was able to register the airline")
        console.log("Is the airline resistered after calling registerAirlines? ", checkRegistration2)
       
    });


    it('(airline) can be registered, but does not participate in contract until it submits funding of 10 ether', async () => {
        try{

            await config.flightSuretyApp.fund.sendTransaction(config.firstAirline, {
                from: config.firstAirline,
                value: 10
            });    

        }
        catch(e){}
       
        let results = await config.flightSuretyApp.isAirline(config.firstAirline);

        assert.equal(results, true, "airline can register another airline if it submits funding of 10 ether");

    });
 

});