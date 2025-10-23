// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RBAC0} from "./RBAC0.sol";

/**
 * @title RBAC1
 * @dev Implements RBAC1 model: adds role hierarchies on top of RBAC0.
 * Roles can inherit permissions from parent roles.
 */
contract RBAC1 is RBAC0 {
    // ---- 角色层次结构 ----
    mapping(bytes32 => bytes32[]) private _parentRoles; // 子 -> 父
    mapping(bytes32 => bytes32[]) private _childRoles;  // 父 -> 子

    // ---- 事件 ----
    event RoleParentAdded(bytes32 indexed role, bytes32 indexed parent);
    event RoleParentRemoved(bytes32 indexed role, bytes32 indexed parent);

    // ---- 管理接口 ----

    /**
     * @dev 为角色设置父角色（继承其权限）
     * 例如：addRoleParent(MANAGER, EMPLOYEE) 表示 MANAGER 继承 EMPLOYEE 的权限。
     */
    function addRoleParent(bytes32 role, bytes32 parent) public onlyRole(getRoleAdmin(role)) {
        require(role != parent, "Cannot inherit self");
        require(!_isParent(role, parent), "Already inherited");
        require(!_isAncestor(parent, role), "Circular inheritance not allowed");

        _parentRoles[role].push(parent);
        _childRoles[parent].push(role);

        emit RoleParentAdded(role, parent);
    }

    /**
     * @dev 移除角色的父角色关系
     */
    function removeRoleParent(bytes32 role, bytes32 parent) public onlyRole(getRoleAdmin(role)) {
        bytes32[] storage parents = _parentRoles[role];
        for (uint i = 0; i < parents.length; i++) {
            if (parents[i] == parent) {
                parents[i] = parents[parents.length - 1];
                parents.pop();
                break;
            }
        }

        bytes32[] storage children = _childRoles[parent];
        for (uint j = 0; j < children.length; j++) {
            if (children[j] == role) {
                children[j] = children[children.length - 1];
                children.pop();
                break;
            }
        }

        emit RoleParentRemoved(role, parent);
    }

    /**
     * @dev 获取角色的所有父角色
     */
    function getParentRoles(bytes32 role) public view returns (bytes32[] memory) {
        return _parentRoles[role];
    }

    /**
     * @dev 获取角色的所有子角色
     */
    function getChildRoles(bytes32 role) public view returns (bytes32[] memory) {
        return _childRoles[role];
    }

    // ---- 权限继承逻辑 ----

    /**
     * @dev 检查用户是否具有指定权限（递归查找父角色）
     */
    function hasPermission(address account, string memory operation, string memory object_) 
        public 
        view 
        override 
        returns (bool) 
    {
        bytes32 role = getActiveRole(account);
        if (role == 0x00) return false;
        return _hasPermissionRecursive(role, operation, object_);
    }

    /**
     * @dev 递归检查角色及其父角色的权限
     */
    function _hasPermissionRecursive(bytes32 role, string memory operation, string memory object_) 
        internal 
        view 
        returns (bool) 
    {
        // 先查自身权限
        Permission[] memory perms = getPermissionsOfRole(role);
        for (uint i = 0; i < perms.length; i++) {
            if (
                keccak256(bytes(perms[i].operation)) == keccak256(bytes(operation)) &&
                keccak256(bytes(perms[i].object_)) == keccak256(bytes(object_))
            ) {
                return true;
            }
        }

        // 向上查父角色
        bytes32[] memory parents = _parentRoles[role];
        for (uint j = 0; j < parents.length; j++) {
            if (_hasPermissionRecursive(parents[j], operation, object_)) {
                return true;
            }
        }
        return false;
    }

    // ---- 防止循环继承 ----

    /**
     * @dev 检查 parent 是否是 role 的上级角色（递归）
     */
    function _isAncestor(bytes32 role, bytes32 potentialAncestor) internal view returns (bool) {
        bytes32[] memory parents = _parentRoles[role];
        for (uint i = 0; i < parents.length; i++) {
            if (parents[i] == potentialAncestor || _isAncestor(parents[i], potentialAncestor)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev 检查角色是否已有某个父角色
     */
    function _isParent(bytes32 role, bytes32 parent) internal view returns (bool) {
        bytes32[] memory parents = _parentRoles[role];
        for (uint i = 0; i < parents.length; i++) {
            if (parents[i] == parent) {
                return true;
            }
        }
        return false;
    }
}
