// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";

contract RBAC is AccessControl {
    // 定义角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor() {
        // 设置合约部署者为默认管理员
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        
    }
    


}