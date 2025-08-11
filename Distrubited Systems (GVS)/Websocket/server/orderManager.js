const addOrder = (peopleOrders, clientName, order) => {
    if (!peopleOrders[clientName]) {
        peopleOrders[clientName] = [];
    }
    peopleOrders[clientName].push(order);
};

const updateOrderStatus = (peopleOrders, clientName, orderId) => {
    if (peopleOrders[clientName]) {
        const orderToUpdate = peopleOrders[clientName].find(order => order.orderId === orderId);
        if (orderToUpdate) {
            orderToUpdate.fulfilled = true;
            return true;
        }
    }
    return false;
};

module.exports = { addOrder, updateOrderStatus };
