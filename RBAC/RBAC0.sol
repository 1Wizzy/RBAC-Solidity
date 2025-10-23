// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "./AccessControl.sol";

contract RBAC0 is AccessControl {
    /**
     * @dev the permission to do the operations to the object
     */
    struct Permission { 
        string[] operation;
        string object;
    }

    struct Role {
        string  roleName;
        bytes32 roleKeccak256;
        Permission        
    }
}
