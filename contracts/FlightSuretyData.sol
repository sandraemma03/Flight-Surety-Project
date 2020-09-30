pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    address[] multiCalls = new address[](0);
    uint private registeredAirlines;
    address[] private airlines;
    uint constant maxAirLineNumber = 4;
    bool private testMode = false;
    address[] voters = new address[](0);
    // uint public registeredAirlines;
    
    
    struct AirLine {
        bool isRegistered;
        uint8 isAdmin;
        address id;
    }

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }

    mapping(string => Flight) private flights;
    mapping(address => uint256) private authorizedContracts;
    mapping(address => AirLine) airLines;      // Mapping for storing airlines
    mapping(address => uint256) funds;
    mapping(bytes32 => uint256) private responses;
    mapping(address => uint256) private wallet; 
    mapping(address => bool) private isActive;
    mapping(bytes32 => uint256) buyFlight;
    mapping(bytes32 => address[]) private insurance;
    mapping(address => uint) private voteCount;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AuthorizedContract(address authContract);
    event DeAuthorizedContract(address authContract);
    event RegisterAirline(address account);
    event RegisterFlight(string indexed account);
    event PurchaseInsurance(address airline, string flight, uint256 timestamp, address sender, uint256 amount);
    event CreditInsurees(address airline, string flight, uint256 timestamp, address passenger, uint256 credit);  
    event FundedLines(address funded);
    event Withdraw(address sender, uint amount);
    

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        airLines[contractOwner] = AirLine({
            isRegistered: true,
            isAdmin: 0,
            id: contractOwner
        });
        isActive[msg.sender] = false;
        registeredAirlines = 1;

        emit RegisterAirline(contractOwner);  
    }

    

   /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not contract owner");
        _;
    }

    

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    function isAirline
                            (
                                address id
                            )
                            external
                            view
                            requireIsOperational
                            returns(bool)
    {
        bool isRegistered = false;
        for(uint i = 0; i < multiCalls.length; i++) {
            if(multiCalls[i] == id) {
                isRegistered = true;
            }
        }
        return airLines[id].isRegistered;
    }

    function isActivated
                                (
                                    address id
                                ) 
                                external 
                                view 
                                requireIsOperational 
                                returns(bool) 
    {
        return isActive[id];
    }

    function authorizeContract
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
        emit AuthorizedContract(contractAddress);
    }

    function deauthorizeContract
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[contractAddress];
        emit DeAuthorizedContract(contractAddress);
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode,
                                address sender
                            ) 
                            external              
                            
    {
        require(mode != operational, "New mode must be different from existing mode");
        require(airLines[sender].isRegistered, "Caller is not registered");

        bool isDuplicate = false;
        for(uint c = 0; c < multiCalls.length; c++) {
            if (multiCalls[c] == sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Duplicate from setopartingstatus. Caller has already called this function.");

        multiCalls.push(sender);
        if (multiCalls.length >= (registeredAirlines.div(2))) {
            operational = mode;      
            multiCalls = new address[](0);      
        }
    }


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

     /**
    * @dev Add a flight to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */ 

    function registerFlight(
                                address airline,
                                string id,
                                uint256 timestamp
                            )
                            external
                            requireIsCallerAuthorized
                            requireIsOperational
    {

        require(airLines[airline].isRegistered, "Airline does not exists");
        flights[id] = Flight({
            isRegistered: true,
            statusCode: 0,
            updatedTimestamp: timestamp,
            airline: airline
            
        });

        emit RegisterFlight(id); 
    }

    

    /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */  

    function registerAirline
                            (   
                                address id
                            )
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            
    {   
        require(!airLines[id].isRegistered, "Airline is already registered.");
        

        if (registeredAirlines < maxAirLineNumber) {
            airLines[id] = AirLine({
                                        id: id,
                                        isRegistered: true,
                                        isAdmin: 0
                                 
            });
            isActive[id] = false;
            multiCalls.push(id); // Add registered address to multicall array 
            registeredAirlines++; // Incrament the number of registered airlines

            emit RegisterAirline(id); 
        
        } else {
            // Avoid registering the same airline twice
            bool isDuplicate = false;
            for (uint i = 0; i < multiCalls.length; i++) {
                if (multiCalls[i] == id) {
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Duplicate. Caller cannot call this function twice");
           

            uint votings = getVotes(id); // Count number of airlines that vote in new airline

            // Check if about 50% of airlines approve registration of new airline
            if ( votings >= registeredAirlines.div(2) ) {
                airLines[id] = AirLine({
                    id: id,
                    isRegistered: true,
                    isAdmin: 0                                       
                });

                multiCalls.push(id); // Add registered address to multicall array
                registeredAirlines++; // Incrament the number of registered airlines
                voteCount[id] = 0; // Reset votes to 0
                voters = new address[](0);
                emit RegisterAirline(id);  
            } else {
                voteCount[id] = 0; // Reset votes to 0
                voters = new address[](0); // Reset voters array
            }
        }
    }  


    /**
    * @dev Approve registration of fifth and subsequent airlines
    *
    */

    function approveAirlineRegistration
                                        (
                                            address airline, 
                                            bool votes
                                        ) 
                                        public 
                                        requireIsOperational 
    {
              
        if(votes == true){
            // Check if calling airlines has voted
            // avoid multiple votes of same airline
            bool isDuplicate = false;

            for(uint c = 0; c < voters.length; c++) {
                if (voters[c] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }

            // Check to avoid registering same airline multiple times
            require(!isDuplicate, "Caller has already called this function.");
            voters.push(msg.sender);
            voteCount[airline] = voteCount[airline].add(1);

            } 
    }

    function getVotes
                    (
                        address airline
                    ) 
                    public 
                    view 
                    returns(uint)
    {
        return voteCount[airline];
    }

    function getRegisteredAirlines
                                    (

                                    ) 
                                    external 
                                    view 
                                    requireIsOperational 
                                    returns(uint256) 
    {
        return registeredAirlines;
    }
   
     /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                (     
                    address airline,
                    string flight,
                    uint256 timestamp,
                    address passenger, 
                    uint256 amount                        
                )
                external
                payable
                requireIsOperational
    {
        require(msg.value <= 1 ether, "amount cannot be higher than 1 ether");
        bytes32 key = getFlightKey(airline, flight, timestamp);
        insurance[key].push(passenger);
        fund(airline);

        
        emit PurchaseInsurance(airline, flight, timestamp, passenger, amount);
    }

    function activeAirline
                            (
                                address id
                            ) 
                            external 
                            payable 
                            requireIsOperational 
    {
        isActive[id] = true;
        fund(id);
        emit FundedLines(id);
    }



    function creditInsurees
                                (
                                    address airline, 
                                    string flight, 
                                    uint256 timestamp, 
                                    address account, 
                                    address passenger
                                )
                                external
                                payable
                                requireIsOperational
    {
        bytes32 key = getFlightKey(airline, flight, timestamp);

        uint256 balance = wallet[account];

        uint256 amount = responses[key];
        uint256 credit = amount.mul(15).div(10);

        wallet[account] = balance.sub(credit);
        wallet[passenger] = wallet[passenger].add(credit);


        emit CreditInsurees(airline, flight, timestamp, passenger, credit);
        
    }


    
    function withdrawFunds
                    (
                        address sender
                    ) 
                    external payable 
                    requireIsOperational
    {
        uint256 withdrawer = wallet[sender];
        wallet[sender] = 0;
        sender.transfer(withdrawer);
        
        emit Withdraw(sender, withdrawer);
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (  
                                 address sender
                            )
                            public
                            payable
                            requireIsOperational
    {
        wallet[sender] = wallet[sender].add(msg.value);
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
                            requireIsOperational
    {
        fund(msg.sender);
    }

    function setTestingMode
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
                            requireIsOperational
    {
        testMode = mode;
    }



      
    
}
