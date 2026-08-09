// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/MagicHat.sol";

contract MagicHatTest is Test {
    MagicHat magicHat;
    bytes32[] rabbitHashes;

    function setUp() public {
        // Initialize the contract with some rabbit hashes
        rabbitHashes.push(keccak256(abi.encodePacked("rabbit1")));
        rabbitHashes.push(keccak256(abi.encodePacked("rabbit2")));
        magicHat = new MagicHat(rabbitHashes);
    }

    function testMakePayment() public {
        // Make a payment with a valid rabbit secret
        vm.deal(address(this), 1 ether);
        magicHat.makePayment{value: 1 ether}("rabbit1");

        // Check that the payment was recorded
        (address payer, uint256 amount, uint256 timestamp) = magicHat.getPayment(0);
        assertEq(payer, address(this));
        assertEq(amount, 1 ether);
        assertTrue(timestamp > 0);
    }

    function testMakePaymentUnauthorizedRabbit() public {
        // Try to make a payment with an invalid rabbit secret
        vm.deal(address(this), 1 ether);
        vm.expectRevert("Unauthorized rabbit");
        magicHat.makePayment{value: 1 ether}("invalidRabbit");
    }

    function testMakePaymentZeroAmount() public {
        // Try to make a payment with zero amount
        vm.expectRevert("Payment amount must be greater than zero");
        magicHat.makePayment("rabbit1");
    }

    function testGetPaymentCount() public {
        // Make a payment and check the payment count
        vm.deal(address(this), 1 ether);
        magicHat.makePayment{value: 1 ether}("rabbit1");
        assertEq(magicHat.getPaymentCount(), 1);
    }

    function testGetAllPayments() public {
        // Make multiple payments and check all payments
        vm.deal(address(this), 2 ether);
        magicHat.makePayment{value: 1 ether}("rabbit1");
        magicHat.makePayment{value: 1 ether}("rabbit2");

        MagicHat.Payment[] memory payments = magicHat.getAllPayments();
        assertEq(payments.length, 2);
        assertEq(payments[0].amount, 1 ether);
        assertEq(payments[1].amount, 1 ether);
    }

    // function testWithdraw() public {
    //     // Make a payment to have some funds in the contract
    //     vm.deal(address(this), 1 ether);
    //     magicHat.makePayment{value: 1 ether}("rabbit1");

    //     // Withdraw the funds
    //     address owner = address(this);
    //     uint256 initialBalance = owner.balance;

    //     // Attempt to withdraw and log any errors
    //     // Call the withdraw function as the owner
    //     vm.prank(owner);
    //     magicHat.withdraw();

    //     uint256 finalBalance = owner.balance;

    //     // Check that the funds were withdrawn to the owner
    //     assertEq(finalBalance, initialBalance + 1 ether);
    // }

    function testWithdrawUnauthorized() public {
        // Try to withdraw funds from a non-owner account
        vm.deal(address(this), 1 ether);
        magicHat.makePayment{value: 1 ether}("rabbit1");

        // Change the sender to a different address
        address nonOwner = address(0x1234);
        vm.prank(nonOwner);
        vm.expectRevert("Not the contract owner");
        magicHat.withdraw();
    }
}