//SPDX-License-Identifier: GPL
pragma solidity ^0.8.15;

/**
 * @title ShopV1
 * @author Daddy69
 * @notice This is a Shop Contract, Can Be used in Real Cafes, Resturants & Shops.
 *         people can order items, events are emitted, employees can fulfill order by looking at these
 *         events.
 *  Features - Add/Remove Employee
 *             Set/Remove Manager
 *             People Can Tip Employees Directly
 */

contract ShopV1 {
    // Owner of the Shop
    address public owner;
    // Manager of the Shop
    address public manager;

    // Item Struct
    struct Item {
        uint16 id;
        uint16 stock;
        string name;
        string description;
        string photo;
        uint256 price;
    }
    // Employeee Stuct
    struct Employee {
        string name;
        address addr;
        uint256 totalTip;
        bool isActive;
    }

    constructor() {
        owner = msg.sender;
    }

    // Total Number of Items
    uint16 public itemCount;
    // Total Number of Employees
    uint16 public employeeCount;
    // Id --> Item mapping
    mapping(uint16 => Item) public _items;
    // Id --> Employee Mapping
    mapping(uint16 => Employee) public _employees;
    // Address --> Bool Mapping
    mapping(address => bool) public isEmployee;

    ///////////////
    /// Events ///
    ///////////////
    event ItemBought(
        address indexed customer,
        uint indexed itemId,
        uint quantity
    );
    event ItemAdded(address indexed staff, uint indexed itemId, uint amount);
    event StockChanged(address indexed staff, uint oldStock, uint newStock);
    event PriceChanged(address indexed staff, uint oldPrice, uint newPrice);
    event EmployeeAdded(string name, address indexed employeeAddr);
    event EmployeeRemoved(address employeeAddr);
    event ManagerChanged(address oldManage, address newManager);

    /////////////////
    /// Modifiers ///
    /////////////////
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyOwnerOrManager() {
        require(msg.sender == manager || msg.sender == owner, "Not Authorized");
        _;
    }

    modifier onlyEmployees() {
        if (!isEmployee[msg.sender]) {
            revert("Not Authorized");
        }
        _;
    }
    modifier onlyAuthorized() {
        require(
            msg.sender == owner ||
                msg.sender == manager ||
                isEmployee[msg.sender],
            "Not Authorized"
        );
        _;
    }
    modifier checkStock(uint16 _itemId, uint256 _quantity) {
        require(_items[_itemId].stock >= _quantity, "Item out of stock");
        _;
    }

    // Add Items
    // Only Authorized Can Add Items i.e, Owner, Manager, Employees
    function addItem(
        uint16 stock,
        string memory name,
        string memory description,
        string memory photo,
        uint256 price
    ) external onlyAuthorized {
        ++itemCount;
        Item storage newItem = _items[itemCount];
        require(bytes(name).length > 0, "Name: Cannot Be Empty");
        require(
            bytes(description).length > 0,
            "Description: Provide Appropriate descrption"
        );
        require(price > 0, "Price: Cannot be Zero");
        newItem.stock = stock;
        newItem.id = itemCount;
        newItem.name = name;
        newItem.description = description;
        newItem.photo = photo;
        newItem.price = price;

        emit ItemAdded(msg.sender, itemCount, stock);
    }

    // Buy Items
    function buyItem(
        uint16 itemId,
        uint16 quantity
    ) external payable checkStock(itemId, quantity) {
        require(itemId <= itemCount && itemId > 0, "Id: Invalid Item Id");
        require(quantity > 0, "Amount: Cannot Be Zero");

        Item storage item = _items[itemId];
        require(item.stock >= quantity, "Not Enough Stock");

        uint itemPrice = item.price;
        uint256 totalCost = itemPrice * quantity;
        require(msg.value >= totalCost, "Insuffcient Amount");
        item.stock -= quantity;

        emit ItemBought(msg.sender, itemId, quantity);
    }

    // Add Employees
    // Only Owner and Manager Can Add New Employees
    function addEmployee(
        string memory name,
        address employeeAddr
    ) external onlyOwnerOrManager {
        require(!isEmployee[employeeAddr], "Already an Employee");
        Employee storage employee = _employees[employeeCount];

        employee.name = name;
        employee.addr = employeeAddr;
        employee.totalTip = 0;
        employee.isActive = true;

        ++employeeCount;

        isEmployee[employeeAddr] = true;
        emit EmployeeAdded(name, employeeAddr);
    }

    // Remove Employee
    // Only Owner and Manager Can Remove Employees
    function removeEmployee(uint16 employeeId) external onlyOwnerOrManager {
        Employee storage employee = _employees[employeeId];
        require(employee.isActive, "Not An Employee");
        employee.isActive = false;
        isEmployee[employee.addr] = false;
        emit EmployeeRemoved(employee.addr);
    }

    // Tip Employee
    // Employee Should Be Active to Revceive Tip
    function tipEmployee(uint16 employeeId) external payable {
        require(employeeId <= employeeCount, "Invalid Id");
        Employee storage employee = _employees[employeeId];
        require(employee.isActive, "Not an Employee");
        require(msg.value > 0, "Amount Must be above 0");
        address employeeAddr = employee.addr;
        (bool success, ) = employeeAddr.call{value: msg.value}("");
        require(success, "Tx Failed");
        employee.totalTip += msg.value;
    }

    // Only Owner Can Set Manage
    // Onwer Can Set him as Manager aswell
    function setManager(address newManager) external onlyOwner {
        manager = newManager;
        emit ManagerChanged(manager, newManager);
    }

    function getItem(uint16 itemId) external view returns (Item memory) {
        return _items[itemId];
    }

    function getEmployee(
        uint16 employeeId
    ) public view returns (Employee memory) {
        return _employees[employeeId];
    }
}
