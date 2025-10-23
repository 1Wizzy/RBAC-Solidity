// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "./AccessControl.sol";

contract RBAC0 is AccessControl {
    address immutable public admin;
    /**
     * @dev have the permission to do all the operation to all the object
     * 
     */
    struct Permission { 
        string[] operation;
        string[] object;
    }

    struct Role {
        string roleName;
        bytes32 roleKeccak256;
        Permission[] permissions;    
    }

    Role[] public roles;
    uint256 public roleIndex = 0;

    constructor() {
        
    }


    function addRole(string memory _roleName) public {
        Role storage role = roles.push();
        bytes32 roleHash = keccak256(abi.encodePacked(_roleName));
        role.roleName = _roleName;
        role.roleKeccak256 = roleHash;
    }   

    
}
