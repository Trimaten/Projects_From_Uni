class Chat {
  constructor() {
    this.boot();
  }

  // Initialization and setup methods
  boot() {
    this.fetchElements();
    this.configureWebSocket();
    this.setupView();
  }

  fetchElements() {
    this.statusElement = document.getElementById("status");
    this.clientCountElement = document.getElementById("client-count");
    this.name = new URLSearchParams(window.location.search).get("name") || "Anonymous";

    const protocol = window.location.protocol === "https:" ? "wss://" : "ws://";
    const server = `${window.location.hostname}:${window.location.port}`;
    this.socketurl = `${protocol}${server}/socket?name=${this.name}`;
    console.log("WebSocket URL with name:", this.socketurl);
  }

  setupView() {
    // Display appropriate view based on whether user is "owner" or a client
    if (this.name === "owner") {
      document.getElementById("owner-view").style.display = "block";
      document.getElementById("client-view").style.display = "none";
    } else {
      document.getElementById("owner-view").style.display = "none";
      document.getElementById("client-view").style.display = "block";
    }
  }

  // WebSocket setup and handlers
  configureWebSocket() {
    this.ws = new WebSocket(this.socketurl);

    this.ws.onopen = () => this.handleOpen();
    this.ws.onmessage = (event) => this.handleMessage(event);
    this.ws.onclose = () => this.handleClose();
  }

  handleOpen() {
    console.log("Connected to server as:", this.name);
    this.ws.send(JSON.stringify({ type: "introduction", name: this.name }));
    if (this.statusElement) this.statusElement.textContent = "Status: Connected";
  }

  handleClose() {
    console.log("Disconnected from server");
    if (this.statusElement) this.statusElement.textContent = "Status: Disconnected";
  }

  handleMessage(event) {
    const data = JSON.parse(event.data);
    switch (data.type) {
      case "menuItems":
        this.buildMenu(data.items);
        break;
      case "clientCount":
        this.updateClientCount(data.count);
        break;
      case "totalValue":
        this.handleTotalValue(data);
        break;
      case "order":
        this.name === "owner" ? this.displayOwnerOrder(data) : this.displayClientOrder(data);
        break;
      case "orderFulfilled":
        this.updateClientOrderStatus(data);
        break;
    }
  }

  handleTotalValue(data) {
    if (this.name === "owner") {
      this.displayOwnerTotalValue(data.client, data.totalValue);
    } else {
      this.displayTotalValue(data);
    }
  }

  // Client and Owner View Methods
  buildMenu(items) {
    const menuContainer = document.getElementById("menu-items");
    menuContainer.innerHTML = ""; // Clear existing menu items

    items.forEach((item) => {
      const itemElement = document.createElement("div");
      itemElement.classList.add("menu-item");
      itemElement.innerHTML = `
        <p>${item.name} - $${item.price}</p>
        <button onclick="chat.orderItem('${item.name}')">Order Now</button>
      `;
      menuContainer.appendChild(itemElement);
    });
  }

  orderItem(itemName) {
    const order = {
      type: "order",
      from: this.name,
      item: itemName,
      orderId: Date.now(), // Unique ID based on timestamp
      timestamp: new Date().toISOString(),
      fulfilled: false,
    };
    console.log("Sending order:", order);
    this.ws.send(JSON.stringify(order));
    this.displayClientOrder(order);
  }

  displayClientOrder(order) {
    const clientOrdersContainer = document.getElementById("client-orders");
    const orderElement = this.createOrderElement(order, "fulfilled");
    clientOrdersContainer.appendChild(orderElement);
  }

  displayOwnerOrder(order) {
    const receivedOrdersContainer = document.getElementById("received-orders");

    // Ensure each client has a unique column
    let clientColumn = document.querySelector(`.client-column[data-client="${order.from}"]`);
    if (!clientColumn) {
      clientColumn = this.createClientColumn(order.from);
      receivedOrdersContainer.appendChild(clientColumn);
    }

    // Append order to client's column
    const orderElement = this.createOrderElement(order, "fulfilled-status");
    if (!order.fulfilled) {
      const fulfillButton = this.createFulfillButton(order, orderElement);
      orderElement.appendChild(fulfillButton);
    }
    clientColumn.appendChild(orderElement);
  }

  createOrderElement(order, fulfilledClass) {
    const orderElement = document.createElement("div");
    orderElement.classList.add("order-card");
    orderElement.dataset.orderId = order.orderId;

    const fulfilledStatusClass = order.fulfilled ? "true" : "";

    orderElement.innerHTML = `
      <p><strong>Item:</strong> ${order.item}</p>
      <p><strong>Time:</strong> ${new Date(order.timestamp).toLocaleString()}</p>
      <p><strong>Fulfilled:</strong> <span class="${fulfilledClass} ${fulfilledStatusClass}">${order.fulfilled}</span></p>
    `;
    return orderElement;
  }

  createClientColumn(clientName) {
    const clientColumn = document.createElement("div");
    clientColumn.classList.add("client-column");
    clientColumn.dataset.client = clientName;

    const clientHeader = document.createElement("h3");
    clientHeader.textContent = clientName;
    clientColumn.appendChild(clientHeader);

    return clientColumn;
  }

  createFulfillButton(order, orderElement) {
    const fulfillButton = document.createElement("button");
    fulfillButton.textContent = "Fulfill Order";
    fulfillButton.onclick = () => this.fulfillOrder(order, orderElement, fulfillButton);
    return fulfillButton;
  }

  fulfillOrder(order, orderElement, button) {
    order.fulfilled = true;

    const fulfilledStatusElement = orderElement.querySelector(".fulfilled-status");
    fulfilledStatusElement.textContent = "true";
    fulfilledStatusElement.classList.add("true");

    button.disabled = true;
    button.textContent = "Order Fulfilled";

    this.ws.send(JSON.stringify({
      type: "orderFulfilled",
      from: "owner",
      item: order.item,
      client: order.from,
      orderId: order.orderId,
      fulfilled: true,
      timestamp: order.timestamp,
    }));
  }

  // Update Order Status Methods
  updateClientOrderStatus(data) {
    const clientOrdersContainer = document.getElementById("client-orders");
    const orderElements = clientOrdersContainer.getElementsByClassName("order-card");

    for (let orderElement of orderElements) {
      if (orderElement.dataset.orderId == data.orderId) {
        const fulfilledStatusElement = orderElement.querySelector(".fulfilled");
        fulfilledStatusElement.textContent = "true";
        fulfilledStatusElement.classList.add("true");
        break;
      }
    }
  }

  // Display Total Value Methods
  displayTotalValue(data) {
    const totalValueContainer = document.getElementById("total-value");
    if (totalValueContainer) {
      totalValueContainer.textContent = `Total Order Value: $${data.totalValue}`;
    }
  }

  displayOwnerTotalValue(clientName, totalValue) {
    const clientColumn = document.querySelector(`.client-column[data-client="${clientName}"]`);
    if (clientColumn) {
      let totalValueElement = clientColumn.querySelector(".total-value");

      if (!totalValueElement) {
        totalValueElement = document.createElement("p");
        totalValueElement.classList.add("total-value");
        clientColumn.insertBefore(totalValueElement, clientColumn.firstChild);
      }

      totalValueElement.textContent = `Total Value: $${totalValue}`;
    }
  }

  // Update client count
  updateClientCount(count) {
    if (this.clientCountElement) {
      this.clientCountElement.textContent = `Clients Connected: ${count}`;
    }
  }
}

// Initialize the Chat instance after the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {
  window.chat = new Chat();
});
