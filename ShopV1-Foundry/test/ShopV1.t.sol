// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ShopV1.sol";

contract CounterTest is Test {
    ShopV1 public shop;

    function setUp() public {
        shop = new ShopV1();
    }

    function testAddItem() public {
        string memory name = "Pizza";
        uint16 stock = 5;
        string memory description = "Sizzling Pizza";
        string memory photo = "pic1";
        uint price = 0.05 ether;

        shop.addItem(stock, name, description, photo, price);
        assertEq(shop.itemCount(), 1);
    }

    function testAddEmployee() public {
        string memory name = "Jason";
        address employee1 = makeAddr("employee1");
        shop.addEmployee(name, employee1);
        assertEq(shop.employeeCount(), 1);
    }

    function testFail_AddEmployee() public {
        address account = makeAddr("account");
        vm.prank(address(account));
        string memory name = "Mark";
        address account1 = makeAddr("account1");
        shop.addEmployee(name, account1);
    }

    function testBuyItem() public {
        testAddItem();
        uint16 itemId = 1;
        uint16 quantity = 2;
        shop.buyItem{value: 2 * 0.05 ether}(itemId, quantity);
        ShopV1.Item memory item = shop.getItem(itemId);
        assertEq(item.stock, 3);
    }

    function testSetManager() public {
        address manager = makeAddr("manager");
        shop.setManager(manager);
        assertEq(shop.manager(), manager);
    }

    function testTipEmployee() public {
        testAddEmployee();
        uint tipAmount = 0.5 ether;
        shop.tipEmployee{value: tipAmount}(0);
        assertEq(shop.getEmployee(0).totalTip, 0.5 ether);
    }
}
