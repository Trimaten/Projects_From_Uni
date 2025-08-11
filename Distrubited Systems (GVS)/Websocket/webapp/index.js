class Chat {
    constructor() {
        this.boot();
    }

    boot() {
        this.fetchElements();
        this.configure();
        this.setup();
        this.role = this.name === 'owner' ? 'owner' : 'client';
        if (this.role === 'client') this.buildMenu();
    }

    buildMenu() {
        const menuItems = [
            { name: 'Pizza', price: 10 },
            { name: 'Burger', price: 5 },
            { name: 'Salad', price: 7 }
        ];
        
        const menuContainer = document.getElementById('menu-items');
        menuItems.forEach(item => {
            const itemElement = document.createElement('div');
            itemElement.classList.add('menu-item');
            itemElement.innerHTML = `
                <p>${item.name} - $${item.price}</p>
                <button onclick="chat.orderItem('${item.name}')">Order Now</button>
            `;
            menuContainer.appendChild(itemElement);
        });
    }

    orderItem(itemName) {
        const order = {
            type: 'order',
            from: this.name,
            item: itemName,
            timestamp: new Date().toISOString(),
            fulfilled: false
        };
        this.ws.send(JSON.stringify(order));
        this.displayClientOrder(order); // Display in the client’s own order history
    }

    displayClientOrder(order) {
        const clientOrdersContainer = document.getElementById('client-orders');
        const orderElement = document.createElement('div');
        orderElement.classList.add('order');
        orderElement.innerHTML = `
            <p>Item: ${order.item}</p>
            <p>Time: ${new Date(order.timestamp).toLocaleString()}</p>
            <p>Fulfilled: ${order.fulfilled}</p>
        `;
        clientOrdersContainer.appendChild(orderElement);
    }

    displayOwnerOrder(order) {
        const receivedOrdersContainer = document.getElementById('received-orders');
        const orderElement = document.createElement('div');
        orderElement.classList.add('order');
        orderElement.innerHTML = `
            <p>Client: ${order.from}</p>
            <p>Item: ${order.item}</p>
            <p>Time: ${new Date(order.timestamp).toLocaleString()}</p>
            <p>Fulfilled: ${order.fulfilled}</p>
        `;
        receivedOrdersContainer.appendChild(orderElement);
    }

    configure() {
        this.ws = new WebSocket(this.socketurl);
        this.ws.onopen = () => {
            console.log('Connected to server');
            this.ws.send(JSON.stringify({ type: 'introduction', name: this.name }));
        };

        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (data.type === 'order' && this.role === 'owner') {
                this.displayOwnerOrder(data); // Show order on owner side
            }
            if (data.type === 'clientCount') this.updateClientCount(data.count);
        };
    }

    fetchElements() {
        this.statusElement = document.getElementById('status');
        this.clientCountElement = document.getElementById('client-count');
        this.name = new URLSearchParams(window.location.search).get('name') || 'Anonymous';
        const protocol = window.location.protocol === 'https:' ? 'wss://' : 'ws://';
        const server = window.location.hostname + ':' + window.location.port;
        this.socketurl = protocol + server + '/socket';
    }
}

// Initialize the Chat instance after the DOM is fully loaded
document.addEventListener('DOMContentLoaded', () => {
    window.chat = new Chat();
});
