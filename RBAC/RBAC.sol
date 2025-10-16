// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";

contract RBAC is AccessControl {
    // 定义角色
    bytes32 public constant SHIPPER_ROLE = keccak256("SHIPPER");        // 发货人
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER");      // 中转站
    bytes32 public constant CONSIGNEE_ROLE = keccak256("CONSIGNEE");    // 收货人
    bytes32 public constant GRANTEE_ROLE = keccak256("GRANTEE");        // 被授权者

    constructor(address adminAddress) {
        // 设置合约为默认管理员
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        // _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // 管理员管理发货人、中转站、收货人、被授权者
        _setRoleAdmin(SHIPPER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TRANSFER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONSIGNEE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(GRANTEE_ROLE, DEFAULT_ADMIN_ROLE);
        // 收货人管理被授权者
        _setRoleAdmin(GRANTEE_ROLE, CONSIGNEE_ROLE);

        // Q: x is the admin of a certain role, does x is the certain role?
        // A: No, and grant a certain role just need x is the certain role's admin.

    }

    function grantShipper(address user) external {
        grantRole(SHIPPER_ROLE, user);
    }

    function grantTransfer(address user) external {
        grantRole(TRANSFER_ROLE, user);
    }

    function grantConsignee(address user) external {
        grantRole(CONSIGNEE_ROLE, user);
    }

    function grantGrantee(address user) external {
        grantRole(GRANTEE_ROLE, user);
    }            

    function hasShipper(address user) external view returns (bool) {
        return hasRole(SHIPPER_ROLE, user);
    }

    function hasTransfer(address user) external view returns (bool) {
        return hasRole(TRANSFER_ROLE, user);
    }

    function hasConsignee(address user) external view returns (bool) {
        return hasRole(CONSIGNEE_ROLE, user);
    }

    function hasGrantee(address user) external view returns (bool) {
        return hasRole(GRANTEE_ROLE, user);
    }

    function revokeGrantee(address user) external{
        revokeRole(GRANTEE_ROLE, user);
    }
    



}