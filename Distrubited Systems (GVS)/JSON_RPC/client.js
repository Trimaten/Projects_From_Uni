const readline = require('readline');

// Helper function to send POST requests
async function sendRequest(method, params = [], id = 1) {
    const url = "http://127.0.0.1:8000/json-rpc";
    const body = {
        jsonrpc: "2.0",
        method: method,
        params: params,
        id: id
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });
        
        const result = await response.json();
        console.log(`Response for ${method}:`, result);
    } catch (error) {
        console.error(`Error in ${method}:`, error);
    }
}

// Helper function to wait for Enter key press
const waitForEnter = () => {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
    return new Promise(resolve => {
        rl.question("Press Enter to continue...", () => {
            rl.close();
            resolve();
        });
    });
}

// Function to handle requests one by one
async function runRequests() {
    // Add devices
    await sendRequest("add_device", [{ type: "light", id: "bedroom", status: "off" }], 1);
    await waitForEnter();
    
    await sendRequest("add_device", [{ type: "light", id: "kitchen", status: "on" }], 2);
    await waitForEnter();

    // Get light status
    await sendRequest("lights", [], 3);
    await waitForEnter();

    // Change light status
    await sendRequest("light_change", ["bedroom"], 4);
    await waitForEnter();
    
    await sendRequest("light_change", ["kitchen"], 5);
    await waitForEnter();

    // Get Roomba status
    await sendRequest("get_roomba_status", [], 6);
    await waitForEnter();

    // Start Roomba
    await sendRequest("start_roomba", [], 7);
    await waitForEnter();

    // Get thermostat temperature
    await sendRequest("get_thermostat_temperature", [], 8);
    await waitForEnter();

    // Delete a device
    await sendRequest("delete_device", ["bedroom"], 9);
    await waitForEnter();

    // Stop the server
    await sendRequest("stop_server", [], 10);
}

// Start the requests
runRequests();
