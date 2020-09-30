
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            let select = DOM.elid('flight');
            contract.flights.forEach(flight => {
                flightoption(flight, select);
            });
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
            console.log("status is true");

        });


        contract.flightSuretyData.events.Withdraw({
            fromBlock: "latest"
        }, function (error, result) {
            if (error) {
                console.log(error)
            } else {
                display('Withdraw Amount', 'Withdraw amount to wallet', [ { label: 'Amount withdrawn', error: error, value: ` ${result.returnValues.amount} at ${new Date()}`} ]);
            }
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            DOM.elid('flight-number').value = "";
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                let selectFlight = DOM.elid('flight');
                flightoption(result, selectFlight);
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: `Flight ${result.flight} scheduled at ${new Date(result.timestamp * 1000)}`} ]);
            });
        });


         // User-submitted transaction
         DOM.elid('buy-insurance').addEventListener('click', () => {
            let amount = DOM.elid('amount').value;
            let flightselect = DOM.elid('flight')
            let flightValue = flightselect.options[flightselect.selectedIndex].value;

            DOM.elid('amount').value = "";
                flightValue = JSON.parse(flightValue);
                contract.buy(flightValue, amount, (error, result) => {
                    if(error) {
                        alert(error);
                    }
                    display('Flight Insurace', 'Purchased Flight Insurance', [ { label: 'Insurance', error: error, value: `Purchased for  ${result.flight} for the amount  ${result.amount} ether of airline  ${result.airline}`} ]);
                    console.log("Insurance purchased");
                    });
        });


        DOM.elid('withdraw-funds').addEventListener('click', () => {
            let amount = DOM.elid('withdraw').value;
            // Write transaction
            contract.withdrawFunds(amount, (error, result) => {
                if(error) {
                    alert(error);
                }
                console.log("Funds withdrawn");
            });
        });

    });

})();


function flightoption(flight, selectQuery) {
    let option = document.createElement("option");
    option.text =  `${flight.flight} added at ${new Date(flight.timestamp)}`;
    option.value = JSON.stringify(flight);
    selectQuery.add(option);
}

function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







