const { addOrder, updateOrderStatus } = require("./orderManager");

const calculateTotalValue = (orders, menuItems) => {
    return orders.reduce((total, order) => {
        const item = menuItems.find(i => i.name === order.item);
        return total + (item ? item.price : 0);
    }, 0);
};

const setupWebSocket = (ws, req, clients, menuItems, peopleOrders, savePeopleOrders) => {
    const urlParams = new URLSearchParams(req.url.split("?")[1]);
    const name = urlParams.get("name") || "Anonymous";
    console.log(`${name} connected`);

    clients.push({ ws, name });

    // Send menu items to non-owner clients when they connect
    if (name !== "owner") {
        ws.send(JSON.stringify({ type: "menuItems", items: menuItems }));
    }

    // Send total order value and existing orders for the owner and clients
    if (name === "owner") {
        Object.keys(peopleOrders).forEach(clientName => {
            const clientOrders = peopleOrders[clientName];
            const totalValue = calculateTotalValue(clientOrders, menuItems);

            ws.send(JSON.stringify({
                type: "totalValue",
                client: clientName,
                totalValue: totalValue
            }));

            clientOrders.forEach(order => {
                ws.send(JSON.stringify({
                    type: "order",
                    from: clientName,
                    item: order.item,
                    orderId: order.orderId,
                    timestamp: order.timestamp,
                    fulfilled: order.fulfilled
                }));
            });
        });
    } else if (peopleOrders[name]) {
        const clientOrders = peopleOrders[name];
        const totalValue = calculateTotalValue(clientOrders, menuItems);

        ws.send(JSON.stringify({
            type: "totalValue",
            client: name,
            totalValue: totalValue
        }));

        clientOrders.forEach(order => {
            ws.send(JSON.stringify({
                type: "order",
                from: name,
                item: order.item,
                orderId: order.orderId,
                timestamp: order.timestamp,
                fulfilled: order.fulfilled
            }));
        });
    }

    ws.on("message", (msg) => {
        const data = JSON.parse(msg);

        if (data.type === "order") {
            console.log(`Received order from ${data.from}: ${data.item}`);
            
            const order = {
                item: data.item,
                orderId: data.orderId,
                timestamp: data.timestamp,
                fulfilled: false
            };
            addOrder(peopleOrders, data.from, order);
            savePeopleOrders(peopleOrders);

            // Calculate and send updated total value to client
            const totalValue = calculateTotalValue(peopleOrders[data.from], menuItems);

            // Send total value to the client who placed the order
            clients.forEach(client => {
                if (client.name === data.from) {
                    client.ws.send(JSON.stringify({
                        type: "totalValue",
                        client: data.from,
                        totalValue: totalValue
                    }));
                }
            });

            // Forward the order to the owner
            clients.forEach((client) => {
                if (client.name === "owner" && client.ws.readyState === client.ws.OPEN) {
                    client.ws.send(JSON.stringify(data));
                    client.ws.send(JSON.stringify({
                        type: "totalValue",
                        client: data.from,
                        totalValue: totalValue
                    }));
                }
            });
        } else if (data.type === "orderFulfilled") {
            console.log(`Order fulfilled by owner: ${data.item}, for client: ${data.client}`);
            
            if (updateOrderStatus(peopleOrders, data.client, data.orderId)) {
                savePeopleOrders(peopleOrders);
            }

            const totalValue = calculateTotalValue(peopleOrders[data.client], menuItems);

            clients.forEach(client => {
                if (client.name === data.client) {
                    client.ws.send(JSON.stringify({
                        type: "orderFulfilled",
                        item: data.item,
                        orderId: data.orderId,
                        fulfilled: true,
                        timestamp: data.timestamp
                    }));
                    client.ws.send(JSON.stringify({
                        type: "totalValue",
                        client: data.client,
                        totalValue: totalValue
                    }));
                }
            });

            clients.forEach((client) => {
                if (client.name === "owner" && client.ws.readyState === client.ws.OPEN) {
                    client.ws.send(JSON.stringify({
                        type: "totalValue",
                        client: data.client,
                        totalValue: totalValue
                    }));
                }
            });
        }
    });

    ws.on("close", () => {
        clients = clients.filter((client) => client.ws !== ws);
        console.log(`${name} disconnected`);
    });
};

module.exports = { setupWebSocket };
