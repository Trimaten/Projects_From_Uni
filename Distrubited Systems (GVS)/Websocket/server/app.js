const express = require("express");
const path = require("path");
const expressWs = require("express-ws");
const { loadMenuItems, loadPeopleOrders, savePeopleOrders, clearPeopleOrders } = require("./fileUtils");
const { setupWebSocket } = require("./wsHandlers");
const app = express();
expressWs(app);

let clients = [];
let menuItems = loadMenuItems();
let peopleOrders = loadPeopleOrders();

// Serve static files from the "webapp" directory
app.use(express.static(path.join(__dirname, "../webapp")));

// WebSocket endpoint
app.ws("/socket", (ws, req) => {
    setupWebSocket(ws, req, clients, menuItems, peopleOrders, savePeopleOrders);
});

// Endpoint to gracefully shut down the server
app.get("/shutdown", (req, res) => {
    console.log("Shutdown request received. Server is shutting down...");
    res.send("Server is shutting down...");

    // Optionally clear people.json on shutdown
    clearPeopleOrders();

    // Graceful shutdown
    server.close(() => {
        console.log("Server closed.");
        process.exit(0); // Exit the process
    });
});

// Start the server and capture the server instance
const server = app.listen(8000, () => {
    console.log("Server listening on port 8000");
});
