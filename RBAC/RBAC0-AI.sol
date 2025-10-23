// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "./AccessControl.sol";

/**
 * @title RBAC0
 * @dev Implements the basic Role-Based Access Control (RBAC0) model.
 * RBAC0 defines a many-to-many relationship between users and roles,
 * and between roles and permissions.
 */
contract RBAC0 is AccessControl {
    // ---- 数据结构 ----

    // 定义权限（Permission），由操作 + 对象 组成
    struct Permission {
        string operation; // 操作（如 read/write/transfer）
        string object_; // 目标对象（如 file, data, contract resource）
    }

    // 角色 -> 权限列表
    mapping(bytes32 => Permission[]) private _rolePermissions;

    // 用户 -> 角色集合（使用 AccessControl 的 grantRole 实现）

    // 用户当前会话激活的角色
    mapping(address => bytes32) private _activeRole;

    // ---- 事件 ----
    event PermissionGranted(
        bytes32 indexed role,
        string operation,
        string object_
    );
    event PermissionRevoked(
        bytes32 indexed role,
        string operation,
        string object_
    );
    event RoleActivated(address indexed user, bytes32 indexed role);




    

    // ---- 角色与权限的分配 ----

    /**
     * @dev 为角色添加权限
     */
    function grantPermission(
        bytes32 role,
        string memory operation,
        string memory object_
    ) public onlyRole(getRoleAdmin(role)) {
        _rolePermissions[role].push(Permission(operation, object_));
        emit PermissionGranted(role, operation, object_);
    }

    /**
     * @dev 从角色移除指定权限
     */
    function revokePermission(
        bytes32 role,
        string memory operation,
        string memory object_
    ) public onlyRole(getRoleAdmin(role)) {
        Permission[] storage perms = _rolePermissions[role];
        for (uint i = 0; i < perms.length; i++) {
            if (
                keccak256(bytes(perms[i].operation)) ==
                keccak256(bytes(operation)) &&
                keccak256(bytes(perms[i].object_)) == keccak256(bytes(object_))
            ) {
                perms[i] = perms[perms.length - 1];
                perms.pop();
                emit PermissionRevoked(role, operation, object_);
                break;
            }
        }
    }

    // ---- 权限检查 ----

    /**
     * @dev 检查账户是否有执行某操作的权限。
     * 逻辑：账户拥有某角色 && 该角色拥有对应权限。
     */
    function hasPermission(
        address account,
        string memory operation,
        string memory object_
    ) public view returns (bool) {
        // 检查当前激活的角色
        bytes32 role = _activeRole[account];
        if (role == 0x00) return false;

        Permission[] storage perms = _rolePermissions[role];
        for (uint i = 0; i < perms.length; i++) {
            if (
                keccak256(bytes(perms[i].operation)) ==
                keccak256(bytes(operation)) &&
                keccak256(bytes(perms[i].object_)) == keccak256(bytes(object_))
            ) {
                return true;
            }
        }
        return false;
    }

    // ---- 会话机制 ----

    /**
     * @dev 用户激活某个角色（即建立“会话”）
     */
    function activateRole(bytes32 role) public {
        require(hasRole(role, msg.sender), "You do not own this role");
        _activeRole[msg.sender] = role;
        emit RoleActivated(msg.sender, role);
    }

    /**
     * @dev 获取用户当前激活的角色
     */
    function getActiveRole(address user) public view returns (bytes32) {
        return _activeRole[user];
    }

    /**
     * @dev 获取角色拥有的全部权限
     */
    function getPermissionsOfRole(
        bytes32 role
    ) public view returns (Permission[] memory) {
        return _rolePermissions[role];
    }
}
