const fs = require("fs");
const path = require("path");

const loadMenuItems = () => {
    try {
        const data = fs.readFileSync(path.join(__dirname, "./data/data.json"), "utf8");
        return JSON.parse(data).menuItems;
    } catch (err) {
        console.error("Error reading data.json:", err);
        return [];
    }
};

const loadPeopleOrders = () => {
    try {
        const data = fs.readFileSync(path.join(__dirname, "./data/people.json"), "utf8");
        return JSON.parse(data);
    } catch (err) {
        console.error("Error loading people.json:", err);
        return {};
    }
};

const savePeopleOrders = (peopleOrders) => {
    fs.writeFileSync(path.join(__dirname, "./data/people.json"), JSON.stringify(peopleOrders, null, 2));
};

const clearPeopleOrders = () => {
    fs.writeFileSync(path.join(__dirname, "./data/people.json"), JSON.stringify({}));
};

module.exports = { loadMenuItems, loadPeopleOrders, savePeopleOrders, clearPeopleOrders };
