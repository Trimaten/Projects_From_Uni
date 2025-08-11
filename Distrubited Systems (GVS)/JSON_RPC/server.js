const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const app = express();
app.use(bodyParser.json());

const devicesFile = './data/devices.json'; // Path to devices.json

// Load devices from the JSON file if it exists
let devices;
if (fs.existsSync(devicesFile)) {
  devices = JSON.parse(fs.readFileSync(devicesFile));
  console.log('Devices loaded from file:', devices);
} else {
  devices = {
    lights: {
      livingRoom: { status: 'off' },
      kitchen: { status: 'off' },
    },
    roomba: { status: 'ready' },
    thermostat: { temperature: 22 }  // Default temperature
  };
  console.log('No existing devices found, using default setup.');
}

// Function to save the devices to the JSON file
function saveDevices() {
  fs.writeFileSync(devicesFile, JSON.stringify(devices, null, 2));
  console.log('Devices saved to file.');
}

// Check if Roomba was working when the server restarts
function handleRoombaRestart() {
  if (devices.roomba.status === 'working') {
    console.log('Roomba was working. Continuing for 30 seconds...');
    setTimeout(() => {
      devices.roomba.status = 'ready';
      saveDevices();  // Save the state after Roomba is ready
      console.log('Roomba is now ready.');
    }, 30000); // 30 seconds
  }
}

// JSON-RPC handler for POST requests
app.post('/json-rpc', (req, res) => {
  console.log("JSON-RPC request received:", req.body);
  
  const { method, params, id } = req.body;
  let response = { jsonrpc: '2.0', id };
  
  try {
    switch (method) {
      case 'lights':
        response.result = devices.lights;
        break;

      case 'light_change':
        const lightId = params[0];
        if (devices.lights[lightId]) {
          devices.lights[lightId].status = devices.lights[lightId].status === 'on' ? 'off' : 'on';
          response.result = `Light ${lightId} is now ${devices.lights[lightId].status}`;
          saveDevices(); // Save the state to the file
        } else {
          response.error = `Light ${lightId} not found`;
        }
        break;

      case 'add_device':
        const newDevice = params[0];
        const deviceType = newDevice.type;
        
        if (deviceType === 'light') {
          const newLightId = newDevice.id;
          const newLightStatus = newDevice.status;
          
          if (!devices.lights[newLightId]) {
            devices.lights[newLightId] = { status: newLightStatus };
            response.result = `New light '${newLightId}' added with status '${newLightStatus}'`;
            saveDevices(); // Save the state to the file
          } else {
            response.error = `Light with id '${newLightId}' already exists.`;
          }
        } else {
          response.error = 'Unsupported device type';
        }
        break;

      case 'delete_device':
        const deleteLightId = params[0];
        if (devices.lights[deleteLightId]) {
          delete devices.lights[deleteLightId];
          response.result = `Light '${deleteLightId}' has been deleted.`;
          saveDevices(); // Save the updated state to the file
        } else {
          response.error = `Light '${deleteLightId}' not found`;
        }
        break;

      case 'start_roomba':
        if (devices.roomba.status === 'working') {
          response.result = 'Roomba already working';
        } else {
          devices.roomba.status = 'working';
          response.result = 'Roomba started working';
          saveDevices();  // Save the state to the file after starting the Roomba
          setTimeout(() => {
            devices.roomba.status = 'ready';
            saveDevices();  // Save the state after Roomba is ready
            console.log('Roomba is now ready again');
          }, 60000);  // 1 minute working time
        }
        break;

      case 'get_roomba_status':
        response.result = devices.roomba.status;
        break;

      case 'get_thermostat_temperature':
        response.result = devices.thermostat.temperature;
        break;

      case 'stop_server':
        response.result = 'Server is shutting down...';
        res.json(response);  // Respond before shutting down
        console.log('Server shutting down...');
        setTimeout(() => {
          server.close(() => {
            console.log('Server successfully stopped.');
            process.exit(0); // Gracefully shut down the process
          });
        }, 1000);
        return;

      default:
        response.error = 'Unknown method';
    }
  } catch (error) {
    console.error(error);
    response.error = 'An error occurred';
  }

  res.json(response);
});

// Start the server and check if Roomba was working
const server = app.listen(8000, () => {
  console.log('Server started on port 8000');
  handleRoombaRestart();  // Check and handle Roomba's status on restart
});
