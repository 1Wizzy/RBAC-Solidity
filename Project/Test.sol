// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../RBAC/RBAC.sol';

contract Test{
    RBAC RBACContract =  new RBAC(address(this));
    function returnBytes32() public pure returns (bytes32) {
        return RBACContract.GRANTEE_ROLE;
    }
}