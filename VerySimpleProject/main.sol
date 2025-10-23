// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract main {
    string[] private message;
    

    event ReadMessage(uint256 indexed messageId, address indexed user);
    event ModifyMessage(uint256 indexed messageId, address indexed user, string oldMessage, string newMessage);


    modifier readPermission(uint256 messageId) {
        
        _;
    }

    function read(uint256 messageId) public returns (string memory) {
        emit ReadMessage(messageId, msg.sender);
        return message[messageId];
    }

    function modify(uint256 messageId, string memory newMessage) public {
        string memory oldMessage = message[messageId];
        message[messageId] = newMessage;
        emit ModifyMessage(messageId, msg.sender, oldMessage, newMessage);
    }



}
