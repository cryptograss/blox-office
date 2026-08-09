// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicHat {
    // Struct to hold payment details
    bytes32[] public rabbitHashes;
    address public owner; // Add owner state variable

    constructor(bytes32[] memory _rabbitHashes) {
        rabbitHashes = _rabbitHashes;
        owner = msg.sender; // Initialize owner
    }

    struct Payment {
        address payer;
        uint256 amount;
        uint256 timestamp;
    }

    // Array to store all payments
    Payment[] public payments;

    // Event to log payment details
    event PaymentMade(address indexed payer, uint256 amount, uint256 timestamp);

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Function to make a payment
    function makePayment(string memory secretRabbit) external payable {
        require(msg.value > 0, "Payment amount must be greater than zero");

        // Check that the hash of the rabbit is in the list of authorized rabbits
        bytes32 rabbitHash = keccak256(abi.encodePacked(secretRabbit));
        bool authorized = false;
        for (uint256 i = 0; i < rabbitHashes.length; i++) {
            if (rabbitHashes[i] == rabbitHash) {
                authorized = true;
                break;
            }
        }
        require(authorized, "Unauthorized rabbit");

        // Add payment to the payments array
        payments.push(Payment({
            payer: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp // Added timestamp
        }));

        // Emit the payment event
        emit PaymentMade(msg.sender, msg.value, block.timestamp);
    }

    // Function to get the number of payments made
    function getPaymentCount() external view returns (uint256) {
        return payments.length;
    }

    // Function to get payment details by index
    function getPayment(uint256 index) external view returns (address, uint256, uint256) {
        require(index < payments.length, "Invalid payment index");
        Payment memory payment = payments[index];
        return (payment.payer, payment.amount, payment.timestamp);
    }

    // Function to get all payments
    function getAllPayments() external view returns (Payment[] memory) {
        return payments;
    }

    // Function to withdraw Ether from the contract
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}